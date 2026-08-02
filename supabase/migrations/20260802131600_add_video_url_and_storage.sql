-- Add video_url to user_listings
ALTER TABLE public.user_listings ADD COLUMN IF NOT EXISTS video_url TEXT NOT NULL DEFAULT '';

-- Create listings_media bucket for images and videos if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'listings_media',
    'listings_media',
    true,
    52428800, -- 50MB limit globally, we'll restrict further in app logic
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime', 'video/webm']
) ON CONFLICT (id) DO NOTHING;

-- Storage policies for listings_media
-- Anyone can read from listings_media
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
TO public 
USING ( bucket_id = 'listings_media' );

-- Authenticated users can upload to listings_media
CREATE POLICY "Auth Upload" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK ( bucket_id = 'listings_media' );

-- Authenticated users can update their own uploads
CREATE POLICY "Auth Update" 
ON storage.objects FOR UPDATE 
TO authenticated 
USING ( bucket_id = 'listings_media' AND auth.uid() = owner )
WITH CHECK ( bucket_id = 'listings_media' AND auth.uid() = owner );

-- Authenticated users can delete their own uploads
CREATE POLICY "Auth Delete" 
ON storage.objects FOR DELETE 
TO authenticated 
USING ( bucket_id = 'listings_media' AND auth.uid() = owner );
