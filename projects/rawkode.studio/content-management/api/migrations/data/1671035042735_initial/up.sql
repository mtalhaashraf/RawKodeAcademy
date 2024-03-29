-- People
CREATE TABLE "people" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "draft" BOOLEAN NOT NULL DEFAULT TRUE,
    "name" TEXT NOT NULL,
    "email" TEXT,
    "biography" TEXT,
    "website" TEXT,
    "github_handle" TEXT NOT NULL CONSTRAINT "github_handle_length" CHECK (char_length("github_handle") <= 39),
    "twitter_handle" TEXT CONSTRAINT "twitter_handle_length" CHECK (
        "twitter_handle" IS NULL
        OR (
            char_length("twitter_handle") >= 4
            AND char_length("twitter_handle") <= 15
        )
    ),
    "youtube_handle" TEXT CONSTRAINT "youtube_handle_length" CHECK (
        "youtube_handle" IS NULL
        OR (
            char_length("youtube_handle") >= 3
            AND char_length("youtube_handle") <= 30
        )
    )
);

CREATE UNIQUE INDEX "person_github_handle" ON "people"("github_handle");
CREATE UNIQUE INDEX "person_twitter_handle" ON "people"("twitter_handle");
CREATE UNIQUE INDEX "person_youtube_handle" ON "people"("youtube_handle");
CREATE UNIQUE INDEX "person_email" ON "people"("email");

-- Shows
CREATE TABLE "shows" (
    "id" TEXT PRIMARY KEY,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "draft" BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE UNIQUE INDEX "show_name" ON "shows"("name");

-- -- Show Episode Count
-- CREATE VIEW show_episode_count AS
--   SELECT author_id, avg(rating)
--     FROM article
--     GROUP BY show_id

-- Show Hosts Function Table
CREATE TABLE "show_hosts" (
    show_id TEXT NOT NULL REFERENCES "shows"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    person_id TEXT NOT NULL REFERENCES "people"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "show_hosts_id" PRIMARY KEY (show_id, person_id)
);

-- Hasura Flattening Views
CREATE VIEW show_hosts_view AS
SELECT show_id,
    people.*
FROM show_hosts
    LEFT JOIN people ON show_hosts.person_id = people.id;

CREATE VIEW host_shows_view AS
SELECT person_id,
    shows.*
FROM show_hosts
    LEFT JOIN shows ON show_hosts.show_id = shows.id;


-- Technologies
CREATE TABLE "technologies" (
    id TEXT PRIMARY KEY,

    name TEXT NOT NULL,
    aliases TEXT [] DEFAULT array []::TEXT [],

    tags TEXT [] DEFAULT array []::TEXT [],

    draft BOOLEAN NOT NULL DEFAULT TRUE,

    tagline TEXT NOT NULL,
    description TEXT NOT NULL,
    website TEXT NOT NULL,
    documentation TEXT NOT NULL,
    logo_url TEXT,

    open_source BOOLEAN NOT NULL DEFAULT FALSE,
    repository TEXT,

    CONSTRAINT open_source_check CHECK (
        open_source IS FALSE OR repository IS NOT NULL
    ),

    twitter_handle TEXT CHECK (
        twitter_handle IS NULL
        OR (
            char_length(twitter_handle) >= 4
            AND char_length(twitter_handle) <= 15
        )
    ),
    youtube_handle TEXT CHECK (
        youtube_handle IS NULL
        OR (
            char_length(youtube_handle) >= 3
            AND char_length(youtube_handle) <= 30
        )
    )
);

-- Episodes
CREATE TYPE "chapter" AS ("time" INTERVAL, "title" TEXT);

CREATE TABLE "episodes" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "draft" BOOLEAN NOT NULL DEFAULT TRUE,
    "title" TEXT NOT NULL,
    show_id TEXT NOT NULL REFERENCES shows("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    "live" BOOLEAN NOT NULL DEFAULT true,
    scheduled_for TIMESTAMP,
    CONSTRAINT is_live CHECK (
        (NOT "live")
        OR (scheduled_for IS NOT NULL)
    ),
    "startedAt" TIMESTAMP,
    "finishedAt" TIMESTAMP,
    youtube_id TEXT,
    youtube_category INTEGER,
    "chapters" chapter [] DEFAULT array []::chapter [],
    "links" TEXT [] DEFAULT array []::TEXT []
);


-- Episode Guests
CREATE TABLE "episode_guests" (
    episode_id TEXT NOT NULL REFERENCES "episodes"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    person_id TEXT NOT NULL REFERENCES "people"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "episode_guests_id" PRIMARY KEY (episode_id, person_id)
);

-- Hasura Flattening Views
CREATE VIEW episode_guests_view AS
SELECT episode_id,
    people.*
FROM episode_guests
    LEFT JOIN people ON episode_guests.person_id = people.id;

CREATE VIEW guest_episodes_view AS
SELECT person_id,
    episodes.*
FROM episode_guests
    LEFT JOIN episodes ON episode_guests.episode_id = episodes.id;


-- Episode Technologies
CREATE TABLE "episode_technologies" (
    episode_id TEXT NOT NULL REFERENCES "episodes"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    technology_id TEXT NOT NULL REFERENCES "technologies"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "episode_technologies_id" PRIMARY KEY (episode_id, technology_id)
);

-- Hasura Flattening Views
CREATE VIEW episode_technologies_view AS
SELECT episode_id,
    technologies.*
FROM episode_technologies
    LEFT JOIN technologies ON episode_technologies.technology_id = technologies.id;

CREATE VIEW technology_episodes_view AS
SELECT technology_id,
    episodes.*
FROM episode_technologies
    LEFT JOIN episodes ON episode_technologies.episode_id = episodes.id;
