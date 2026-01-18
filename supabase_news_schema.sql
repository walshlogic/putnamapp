-- News Sources Table
-- Stores information about news sources/APIs
CREATE TABLE IF NOT EXISTS public.news_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id TEXT UNIQUE NOT NULL, -- e.g., 'newsapi', 'thenewsapi'
    name TEXT NOT NULL,
    description TEXT,
    url TEXT,
    category TEXT, -- e.g., 'general', 'technology', 'business'
    language TEXT DEFAULT 'en',
    country TEXT DEFAULT 'us',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- News Articles Table
-- Stores normalized news articles from various sources
CREATE TABLE IF NOT EXISTS public.news_articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID NOT NULL REFERENCES public.news_sources(id) ON DELETE CASCADE,
    external_id TEXT NOT NULL, -- Unique ID from the news API
    title TEXT NOT NULL,
    description TEXT,
    content TEXT, -- Full article content if available
    url TEXT NOT NULL,
    image_url TEXT,
    author TEXT,
    published_at TIMESTAMPTZ NOT NULL,
    category TEXT, -- e.g., 'general', 'technology', 'business', 'health'
    tags TEXT[], -- Array of tags/topics
    language TEXT DEFAULT 'en',
    country TEXT DEFAULT 'us',
    -- Metadata
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Ensure unique articles per source
    UNIQUE(source_id, external_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_news_articles_published_at ON public.news_articles(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_articles_category ON public.news_articles(category);
CREATE INDEX IF NOT EXISTS idx_news_articles_source_id ON public.news_articles(source_id);
CREATE INDEX IF NOT EXISTS idx_news_articles_tags ON public.news_articles USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_news_articles_created_at ON public.news_articles(created_at DESC);

-- Full-text search index for title and description
CREATE INDEX IF NOT EXISTS idx_news_articles_search ON public.news_articles USING GIN(
    to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(description, ''))
);

-- Updated_at trigger function (if not exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_news_sources_updated_at ON public.news_sources;
CREATE TRIGGER update_news_sources_updated_at
    BEFORE UPDATE ON public.news_sources
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_news_articles_updated_at ON public.news_articles;
CREATE TRIGGER update_news_articles_updated_at
    BEFORE UPDATE ON public.news_articles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
ALTER TABLE public.news_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.news_articles ENABLE ROW LEVEL SECURITY;

-- Allow public read access to news sources
DROP POLICY IF EXISTS "Public can read news sources" ON public.news_sources;
CREATE POLICY "Public can read news sources"
    ON public.news_sources
    FOR SELECT
    USING (true);

-- Allow public read access to news articles
DROP POLICY IF EXISTS "Public can read news articles" ON public.news_articles;
CREATE POLICY "Public can read news articles"
    ON public.news_articles
    FOR SELECT
    USING (true);

-- Allow service role to insert/update news articles (for Python script)
DROP POLICY IF EXISTS "Service role can manage news articles" ON public.news_articles;
CREATE POLICY "Service role can manage news articles"
    ON public.news_articles
    FOR ALL
    USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role can manage news sources" ON public.news_sources;
CREATE POLICY "Service role can manage news sources"
    ON public.news_sources
    FOR ALL
    USING (auth.role() = 'service_role');

-- Insert default news source (NewsAPI)
INSERT INTO public.news_sources (source_id, name, description, url, category, language, country)
VALUES (
    'newsapi',
    'NewsAPI',
    'NewsAPI.org - Free news API',
    'https://newsapi.org',
    'general',
    'en',
    'us'
)
ON CONFLICT (source_id) DO NOTHING;

