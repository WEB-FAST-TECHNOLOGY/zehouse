-- Drop the old foreign keys pointing to auth.users
ALTER TABLE public.conversations
    DROP CONSTRAINT IF EXISTS conversations_participant_one_fkey,
    DROP CONSTRAINT IF EXISTS conversations_participant_two_fkey;

-- Add new foreign keys pointing to public.user_profiles
ALTER TABLE public.conversations
    ADD CONSTRAINT conversations_participant_one_fkey
        FOREIGN KEY (participant_one)
        REFERENCES public.user_profiles(id)
        ON DELETE CASCADE,
    ADD CONSTRAINT conversations_participant_two_fkey
        FOREIGN KEY (participant_two)
        REFERENCES public.user_profiles(id)
        ON DELETE CASCADE;
