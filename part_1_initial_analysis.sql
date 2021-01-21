--Part I: Investigate the existing schema

--len of urls
SELECT url, LENGTH(url)
FROM bad_posts
WHERE url IS NOT NULL
ORDER BY LENGTH(url) DESC
LIMIT 10;

--duplicates in usernames
select * from bad_posts t1
where (select count(*) from bad_posts t2
where t1.username = t2.username) > 1
order by username

--MISC TESTING
DROP TABLE users CASCADE;
DROP TABLE topics CASCADE;
DROP TABLE posts CASCADE;
DROP TABLE comments CASCADE;
DROP TABLE votes CASCADE;

TRUNCATE table_name RESTART IDENTITY CASCADE;

SELECT count(title) FROM bad_posts
    WHERE url IS NOT NULL AND text_content IS NOT NULL; --url:37506 text:12494

ALTER TABLE /**/ ALTER COLUMN /**/ TYPE

--total restart
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;