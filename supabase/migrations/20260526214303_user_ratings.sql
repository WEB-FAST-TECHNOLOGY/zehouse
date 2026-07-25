-- Migration: user_ratings table for landlords, agents, and general users
-- Timestamp: 20260526214303

-- General user ratings table (for landlords, agents, etc.)
CREATE TABLE IF NOT EXISTS public.user_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rated_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  rater_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  context TEXT, -- e.g. 'landlord', 'agent', 'tenant'
  listing_id TEXT, -- optional reference to a listing
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(rated_user_id, rater_id)
);

-- RLS for user_ratings
ALTER TABLE public.user_ratings ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_ratings' AND policyname = 'user_ratings_select'
  ) THEN
    CREATE POLICY user_ratings_select ON public.user_ratings
      FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_ratings' AND policyname = 'user_ratings_insert'
  ) THEN
    CREATE POLICY user_ratings_insert ON public.user_ratings
      FOR INSERT WITH CHECK (auth.uid() = rater_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_ratings' AND policyname = 'user_ratings_update_own'
  ) THEN
    CREATE POLICY user_ratings_update_own ON public.user_ratings
      FOR UPDATE USING (auth.uid() = rater_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_ratings' AND policyname = 'user_ratings_delete_own'
  ) THEN
    CREATE POLICY user_ratings_delete_own ON public.user_ratings
      FOR DELETE USING (auth.uid() = rater_id);
  END IF;
END $$;

-- Also add update/delete policies for professional_reviews if not exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'professional_reviews' AND policyname = 'reviews_update_own'
  ) THEN
    CREATE POLICY reviews_update_own ON public.professional_reviews
      FOR UPDATE USING (auth.uid() = reviewer_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'professional_reviews' AND policyname = 'reviews_delete_own'
  ) THEN
    CREATE POLICY reviews_delete_own ON public.professional_reviews
      FOR DELETE USING (auth.uid() = reviewer_id);
  END IF;
END $$;
