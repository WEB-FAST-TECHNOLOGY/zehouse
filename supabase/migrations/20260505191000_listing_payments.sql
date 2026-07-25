-- Migration: Track $10 listing publication payments for non-professional users
-- Each row records a successful payment before a listing is published

CREATE TABLE IF NOT EXISTS public.listing_payments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount_usd integer NOT NULL DEFAULT 10,
  currency text NOT NULL DEFAULT 'USD',
  payment_provider text NOT NULL, -- 'cinetpay' or 'moneroo'
  transaction_id text,
  status text NOT NULL DEFAULT 'completed', -- 'pending', 'completed', 'failed'
  listing_id uuid, -- can be linked to the listing after creation
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.listing_payments ENABLE ROW LEVEL SECURITY;

-- Users can only see their own payments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'listing_payments' AND policyname = 'Users can view own listing payments'
  ) THEN
    CREATE POLICY "Users can view own listing payments"
      ON public.listing_payments
      FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- Users can insert their own payment records
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'listing_payments' AND policyname = 'Users can insert own listing payments'
  ) THEN
    CREATE POLICY "Users can insert own listing payments"
      ON public.listing_payments
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
