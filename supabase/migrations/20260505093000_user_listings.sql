-- User Listings table: stores user-generated property listings with geo coordinates
CREATE TABLE IF NOT EXISTS public.user_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    price INTEGER NOT NULL DEFAULT 0,
    surface DOUBLE PRECISION NOT NULL DEFAULT 0,
    rooms INTEGER NOT NULL DEFAULT 1,
    listing_type TEXT NOT NULL DEFAULT 'sale',
    property_type TEXT NOT NULL DEFAULT 'Appartement',
    description TEXT NOT NULL DEFAULT '',
    image_url TEXT NOT NULL DEFAULT '',
    lat DOUBLE PRECISION NOT NULL DEFAULT 48.8566,
    lng DOUBLE PRECISION NOT NULL DEFAULT 2.3522,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_listings_user_id ON public.user_listings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_listings_is_active ON public.user_listings(is_active);
CREATE INDEX IF NOT EXISTS idx_user_listings_listing_type ON public.user_listings(listing_type);
CREATE INDEX IF NOT EXISTS idx_user_listings_created_at ON public.user_listings(created_at DESC);

-- Enable RLS
ALTER TABLE public.user_listings ENABLE ROW LEVEL SECURITY;

-- Public can read all active listings (for map display)
DROP POLICY IF EXISTS "public_can_read_user_listings" ON public.user_listings;
CREATE POLICY "public_can_read_user_listings"
ON public.user_listings
FOR SELECT
TO public
USING (is_active = true);

-- Authenticated users can insert their own listings
DROP POLICY IF EXISTS "users_can_insert_own_user_listings" ON public.user_listings;
CREATE POLICY "users_can_insert_own_user_listings"
ON public.user_listings
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Authenticated users can update their own listings
DROP POLICY IF EXISTS "users_can_update_own_user_listings" ON public.user_listings;
CREATE POLICY "users_can_update_own_user_listings"
ON public.user_listings
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Authenticated users can delete their own listings
DROP POLICY IF EXISTS "users_can_delete_own_user_listings" ON public.user_listings;
CREATE POLICY "users_can_delete_own_user_listings"
ON public.user_listings
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_user_listings_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_user_listings_updated_at ON public.user_listings;
CREATE TRIGGER update_user_listings_updated_at
    BEFORE UPDATE ON public.user_listings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_listings_updated_at();

-- Sample listing using existing user
DO $$
DECLARE
    existing_user_id UUID;
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'user_profiles'
    ) THEN
        SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;

        IF existing_user_id IS NOT NULL THEN
            INSERT INTO public.user_listings (
                id, user_id, title, address, price, surface, rooms,
                listing_type, property_type, description, image_url, lat, lng
            ) VALUES
            (
                gen_random_uuid(), existing_user_id,
                'Appartement Lumineux République',
                '15 Place de la République, 75011 Paris',
                420000, 65.0, 3, 'sale', 'Appartement',
                'Bel appartement lumineux avec vue dégagée, proche métro.',
                'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg',
                48.8675, 2.3634
            ),
            (
                gen_random_uuid(), existing_user_id,
                'Studio Cosy Nation',
                '7 Rue de la Nation, 75012 Paris',
                980, 28.0, 1, 'rent', 'Studio',
                'Studio entièrement rénové, idéal pour étudiant ou jeune actif.',
                'https://images.pexels.com/photos/1648776/pexels-photo-1648776.jpeg',
                48.8484, 2.3961
            )
            ON CONFLICT (id) DO NOTHING;
        ELSE
            RAISE NOTICE 'No existing users found. Skipping sample listings.';
        END IF;
    ELSE
        RAISE NOTICE 'Table user_profiles does not exist. Skipping sample listings.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Sample listings insertion failed: %', SQLERRM;
END $$;
