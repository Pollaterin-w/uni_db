CREATE DOMAIN role_name_domain AS VARCHAR(50)
	CHECK (VALUE IN('admin', 'author', 'viewer'));

	
CREATE TABLE IF NOT EXISTS role (
    role_id SERIAL PRIMARY KEY,
    role_name role_name_domain UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS permission (
    permission_id SERIAL PRIMARY KEY,
    permission_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL REFERENCES role(role_id), 
    user_name TEXT NOT NULL,
    surname TEXT NOT NULL,
    email VARCHAR(100) UNIQUE,
	password_hash VARCHAR(150) NOT NULL,
	avatar_url VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);


CREATE TABLE IF NOT EXISTS role_permission (
    role_id INTEGER NOT NULL REFERENCES role(role_id) ON DELETE CASCADE, 
    permission_id INTEGER NOT NULL REFERENCES permission(permission_id) ON DELETE CASCADE, 
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS folder (
    folder_id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE, 
	parent_folder_id INTEGER REFERENCES folder(folder_id) ON DELETE CASCADE, 
    folder_name VARCHAR(100) NOT NULL,
    description TEXT,
	is_shared BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_folder_owner ON folder(owner_id);

CREATE TABLE IF NOT EXISTS images (
    image_id SERIAL PRIMARY KEY,
	owner_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE, 
	folder_id INTEGER NOT NULL REFERENCES folder(folder_id) ON DELETE CASCADE, 
	media_url VARCHAR(150) NOT NULL,
    title VARCHAR(100),
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
	is_shared BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_images_title ON images(title);


CREATE TABLE IF NOT EXISTS shares (
    share_id SERIAL PRIMARY KEY,
    from_user_id INTEGER NOT NULL REFERENCES users(user_id),
    to_user_id INTEGER NOT NULL REFERENCES users(user_id),  
    image_id INTEGER REFERENCES images(image_id) ON DELETE CASCADE, 
    folder_id INTEGER REFERENCES folder(folder_id) ON DELETE CASCADE, 
    share_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_share_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT check_share_target CHECK(
		(image_id IS NOT NULL AND folder_id IS NULL) OR
		(image_id IS NULL AND folder_id IS NOT NULL)
	),
	  CONSTRAINT check_share_self CHECK (from_user_id <> to_user_id)
	
);

CREATE INDEX idx_shares_to_user ON shares(to_user_id);
CREATE INDEX idx_shares_image ON shares(image_id);
CREATE INDEX idx_shares_folder ON shares(folder_id);

CREATE OR REPLACE FUNCTION get_users_role (p_user_id SERIAL)
RETURN role_name_domain AS $$
DECLARE
	v_role role_name_domain;
BEGIN 
	SELECT role.role_name INTO v_role
	FROM users
	JOIN role 
	ON users.role_id = role.role_id
	WHERE users.user_id = p_user_id
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION has_permission(p_user_id INTEGER, p_permission_name VARCHAR(100))
RETURNS BOOLEAN AS $$
DECLARE
    v_has BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM users
        JOIN role_permission ON users.role_id = role_permission.role_id
        JOIN permission ON role_permission.permission_id = permission.permission_id
        WHERE users.user_id = p_user_id
          AND permission.permission_name = p_permission_name
    ) INTO v_has;

    RETURN v_has;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION can_view_image(p_user_id INTEGER, p_image_id INTEGER)
RETURN BOOLEAN AS $$
DECLARE
BEGIN
	WHERE i.image_id = p_image_id
		AND (
        i.owner_id = p_user_id        
        OR i.is_public = TRUE         
     	    OR EXISTS (                  
            SELECT 1 FROM shares
            WHERE to_user_id = p_user_id
                AND image_id = p_image_id
      )
  )
END;
$$ LANGUAGE plpgsql;



