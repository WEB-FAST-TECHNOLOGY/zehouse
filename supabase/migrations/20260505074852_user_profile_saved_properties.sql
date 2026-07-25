-- User Profile: add phone column + saved_properties table

-- 1. Add phone column to user_profiles (idempotent)
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS phone TEXT NOT NULL DEFAULT '';

-- 2. Saved properties table
CREATE TABLE IF NOT EXISTS public.saved_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    property_id TEXT NOT NULL,
    title TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    price INTEGER NOT NULL DEFAULT 0,
    listing_type TEXT NOT NULL DEFAULT 'sale',
    surface DOUBLE PRECISION NOT NULL DEFAULT 0,
    rooms INTEGER NOT NULL DEFAULT 0,
    image_url TEXT NOT NULL DEFAULT '',
    semantic_label TEXT NOT NULL DEFAULT '',
    saved_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_property UNIQUE (user_id, property_id)
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_saved_properties_user_id ON public.saved_properties(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_properties_saved_at ON public.saved_properties(saved_at DESC);

-- 4. Enable RLS
ALTER TABLE public.saved_properties ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for saved_properties
DROP POLICY IF EXISTS "users_manage_own_saved_properties" ON public.saved_properties;
CREATE POLICY "users_manage_own_saved_properties"
ON public.saved_properties
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
