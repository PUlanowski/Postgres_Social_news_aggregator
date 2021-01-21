--DDL Creating Tables, Constraints and Indexes
--NOTE: execution in psql: 
--1. TABLE creation
--data migration (Part 3)
--2. ALTER TABLE additional constraints
--3. INDEXES


----1. TABLE creation
--USERS
--last _login_date it's for new users sake when first created account will leave current date
CREATE TABLE users (
    id SERIAL
        CONSTRAINT pk_users PRIMARY KEY,
    username VARCHAR(25) NOT NULL 
        CONSTRAINT unique_user UNIQUE,
    last_login_date DATE NOT NULL DEFAULT CURRENT_DATE 
);
--TOPICS
--for topic_timestamp using timestamp without time zone because given business context i think it's not required
CREATE TABLE topics (
    id SERIAL
        CONSTRAINT pk_topics PRIMARY KEY,
    topic_name VARCHAR(30) NOT NULL,
    topic_descr VARCHAR(500),
    topic_timestamp TIMESTAMP
);
--POSTS
CREATE TABLE posts (
    id SERIAL 
        CONSTRAINT pk_posts PRIMARY KEY,
    topic_id INTEGER NOT NULL,
    user_id INTEGER,
    post_title VARCHAR(100) NOT NULL,
    post_url VARCHAR(100),
    post_text TEXT,
    post_timestamp TIMESTAMP
);
--COMMENTS
--for parent_id rule would be if parent_id = NULL then it's main comment, rest is cascading freeley from children to parents
CREATE TABLE comments (
    id SERIAL 
        CONSTRAINT pk_comments PRIMARY KEY,
    parent_id INTEGER,
    user_id INTEGER,
    post_id INTEGER,
    comment_text TEXT NOT NULL,
    comment_timestamp TIMESTAMP
);
--VOTES
--1 for upvote and -1 for downvote
CREATE TABLE votes (
    id SERIAL
        CONSTRAINT pk_votes PRIMARY KEY,
    post_id INTEGER,
    user_id INTEGER,
    vote SMALLINT
        CONSTRAINT vote_up_down CHECK (vote = 1 OR vote = -1),
    vote_timestamp TIMESTAMP
);

----2. ALTER TABLE additional constraints after migration

--USERS
ALTER TABLE users
    ADD CONSTRAINT username_not_empty CHECK (LENGTH(TRIM(username))>0);

--TOPICS
ALTER TABLE topics
    ADD CONSTRAINT topic_not_empty CHECK (LENGTH(TRIM(topic_name))>0);

--POSTS
--check_one_value: here we ensure only one of columns can be populated
ALTER TABLE posts
    ADD CONSTRAINT chck_one_value CHECK (
        (post_url IS NULL AND post_text IS NOT NULL)
        OR
        (post_text IS NULL AND post_url IS NOT NULL)
         ),
    ADD CONSTRAINT fk_posts_users FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL,
    ADD CONSTRAINT fk_posts_topics FOREIGN KEY (topic_id) REFERENCES topics(id)
        ON DELETE CASCADE,
    ADD CONSTRAINT post_title_not_empty CHECK (LENGTH(TRIM(post_title))>0);

--COMMENTS
ALTER TABLE comments
    ADD CONSTRAINT fk_comments_users FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL,
    ADD CONSTRAINT comment_not_empty CHECK (LENGTH(TRIM(comment_text))>0),
    ADD CONSTRAINT fk_comments_posts FOREIGN KEY (post_id) REFERENCES posts(id)
        ON DELETE CASCADE,
    ADD CONSTRAINT fk_comments_parent FOREIGN KEY (parent_id) REFERENCES comments(id)
        ON DELETE CASCADE;

--VOTES
ALTER TABLE votes
    ADD CONSTRAINT fk_votes_users FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL,
    ADD CONSTRAINT unique_vote_id UNIQUE (id),
    ADD CONSTRAINT fk_votes_posts FOREIGN KEY (post_id) REFERENCES posts(id)
        ON DELETE CASCADE;

----3. INDEXES after migration
--USERS
CREATE INDEX find_username ON users(username);
CREATE INDEX find_last_login ON users(last_login_date);

--TOPICS
--additional conditions on find_topic_name will let incomplete, case insensitive search
CREATE INDEX find_topic_name ON topics(LOWER(topic_name) VARCHAR_PATTERN_OPS);

--POSTS
CREATE INDEX find_post_by_user ON posts(user_id);
CREATE INDEX find_post_with_url ON posts(post_url);
CREATE INDEX find_posts_in_topic ON posts(topic_id); 
--COMMENTS
CREATE INDEX find_parents_only ON comments(parent_id) WHERE parent_id IS NULL;
CREATE INDEX find_comment_by_user ON comments(user_id);
CREATE INDEX find_all_children ON comments(id) WHERE parent_id IS NOT NULL;

--VOTES
CREATE INDEX vote_calc ON votes(post_id);