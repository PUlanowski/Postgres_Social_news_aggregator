--DML migrating data

/*
CREATE TABLE bad_posts (
    id SERIAL PRIMARY KEY, --redundant 
    topic VARCHAR(50), --done in topics table 
    username VARCHAR(50), --done 9984
    title VARCHAR(150), --post title done in posts table with topic id's assigned
    url VARCHAR(4000) DEFAULT NULL, -- post url
    text_content TEXT DEFAULT NULL, --post text
    upvotes TEXT,--done users 249799
    downvotes TEXT --done users 249911
);
CREATE TABLE bad_comments (
    id SERIAL PRIMARY KEY, -- redundant
    username VARCHAR(50), --distinct 100
    post_id BIGINT, --migrated from new posts table
    text_content TEXT -- migrated 100k
);
*/
----NOTE: migration need to be done in folowing order:

/*************************users migration*************************/
CREATE TABLE temp (
    username VARCHAR
);

INSERT INTO temp(username)
    SELECT DISTINCT username --9984
    FROM bad_comments;

INSERT INTO temp(username)
    SELECT DISTINCT username --100
    FROM bad_posts;

INSERT INTO temp(username)
    SELECT regexp_split_to_table (upvotes, ',') --249799
    FROM bad_posts;

INSERT INTO temp(username)
    SELECT regexp_split_to_table (downvotes, ',') --249911
    FROM bad_posts; -- 509794 not distinct values

INSERT INTO users(username)
    SELECT DISTINCT username --11077
    FROM temp;

DROP TABLE temp;

/*************************topic migration #1**********************/

INSERT INTO topics(topic_name)
    SELECT topic FROM bad_posts;

/*************************posts migration*************************/

INSERT INTO posts(topic_id, post_title, post_url, post_text, user_id)
    SELECT t.id, title, url, text_content, u.id FROM bad_posts AS bp
    JOIN topics AS t
        ON t.topic_name = bp.topic
    JOIN users AS u
    ON bp.username = u.username;



/*************************topic migration #2***********************/

INSERT INTO topics(topic_name, post_id)
    SELECT bp.topic, p.id as post_id FROM bad_posts AS bp
    JOIN posts AS p
        ON bp.title = p.post_title;


/*************************comments migration***********************/

INSERT INTO comments(comment_text, post_id, user_id) --100k comments inputted for 10k distinct post id's
    SELECT bc.text_content, p.id, u.id FROM bad_comments AS bc
    JOIN bad_posts AS bp
        ON bc.post_id = bp.id
    JOIN posts AS p
        ON bp.title = p.post_title
    JOIN users AS u
        ON bp.username = u.username;


/*************************votes migration*************************/

CREATE TABLE temp2(
    post_id INTEGER,
    vote_name VARCHAR,
    vote_name_id INTEGER,
    up_down SMALLINT
);

INSERT INTO temp2(post_id, vote_name, vote_name_id, up_down)
    SELECT 
    p.id as post_id,
    regexp_split_to_table (bp.upvotes, ','),
    u.id as user_id,
    1
    FROM bad_posts AS bp
    JOIN users AS u
        ON bp.username = u.username
    JOIN posts AS p
        ON p.post_title = bp.title;

INSERT INTO temp2(post_id, vote_name, vote_name_id, up_down)
    SELECT 
    p.id as post_id,
    regexp_split_to_table (bp.downvotes, ','),
    u.id as user_id,
    -1
    FROM bad_posts AS bp
    JOIN users AS u
        ON bp.username = u.username
    JOIN posts AS p
        ON p.post_title = bp.title;

INSERT INTO votes (post_id, user_id, vote)
    SELECT post_id, vote_name_id, up_down FROM temp2;

DROP TABLE temp2;