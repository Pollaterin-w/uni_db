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
    update_share_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP

	CONSTRAINT check_share_target CHECK(
		(image_id NOT NULL AND folder_id IS NULL) OR
		(Image_id IS NULL AND folder_id NOT NULL)
	),
	  CONSTRAINT check_share_self CHECK (from_user_id <> to_user_id)
	
);

CREATE INDEX idx_shares_to_user ON shares(to_user_id);
CREATE INDEX idx_shares_image ON shares(image_id);
CREATE INDEX idx_shares_folder ON shares(folder_id);

