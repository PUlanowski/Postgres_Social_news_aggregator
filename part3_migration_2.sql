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
    SELECT DISTINCT username
    FROM bad_comments;

INSERT INTO temp(username)
    SELECT DISTINCT username
    FROM bad_posts;

INSERT INTO temp(username)
    SELECT DISTINCT(regexp_split_to_table (upvotes, ','))
    FROM bad_posts;

INSERT INTO temp(username)
    SELECT DISTINCT(regexp_split_to_table (downvotes, ','))
    FROM bad_posts;

INSERT INTO users(username)
    SELECT DISTINCT username
    FROM temp;

DROP TABLE temp;

/*************************topic migration*************************/

INSERT INTO topics(topic_name)
    SELECT DISTINCT topic FROM bad_posts;

/*************************posts migration*************************/

INSERT INTO posts(
    user_id,
    topic_id,
    post_title,
    post_url,
    post_text
    )
SELECT u.id,
    t.id,
    LEFT(bp.title, 100),
    bp.url,
    bp.text_content
FROM bad_posts AS bp
JOIN topics AS t ON t.topic_name = bp.topic
JOIN users AS u ON bp.username = u.username;


/*************************comments migration***********************/

INSERT INTO comments(
    user_id,
    post_id,
    comment_text
    )
SELECT u.id,
    bc.post_id,
    bc.text_content
FROM bad_comments AS bc
JOIN users AS u ON bc.username = u.username;


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