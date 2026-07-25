-- Migration: professional_reviews and listing_reports tables
-- Timestamp: 20260507151130

-- Professional reviews table
CREATE TABLE IF NOT EXISTS public.professional_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(professional_id, reviewer_id)
);

-- Listing reports table
CREATE TABLE IF NOT EXISTS public.listing_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id TEXT NOT NULL,
  reporter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add phone and is_verified columns to user_profiles if not exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'phone'
  ) THEN
    ALTER TABLE public.user_profiles ADD COLUMN phone TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'is_verified'
  ) THEN
    ALTER TABLE public.user_profiles ADD COLUMN is_verified BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'avatar_url'
  ) THEN
    ALTER TABLE public.user_profiles ADD COLUMN avatar_url TEXT;
  END IF;
END $$;

-- RLS for professional_reviews
ALTER TABLE public.professional_reviews ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'professional_reviews' AND policyname = 'reviews_select'
  ) THEN
    CREATE POLICY reviews_select ON public.professional_reviews
      FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'professional_reviews' AND policyname = 'reviews_insert'
  ) THEN
    CREATE POLICY reviews_insert ON public.professional_reviews
      FOR INSERT WITH CHECK (auth.uid() = reviewer_id);
  END IF;
END $$;

-- RLS for listing_reports
ALTER TABLE public.listing_reports ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'listing_reports' AND policyname = 'reports_insert'
  ) THEN
    CREATE POLICY reports_insert ON public.listing_reports
      FOR INSERT WITH CHECK (auth.uid() = reporter_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'listing_reports' AND policyname = 'reports_select_own'
  ) THEN
    CREATE POLICY reports_select_own ON public.listing_reports
      FOR SELECT USING (auth.uid() = reporter_id);
  END IF;
END $$;
