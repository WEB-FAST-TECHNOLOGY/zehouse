-- Test Accounts: buyer, seller, agent with demo data for full app testing

DO $$
DECLARE
    buyer_uuid  UUID := gen_random_uuid();
    seller_uuid UUID := gen_random_uuid();
    agent_uuid  UUID := gen_random_uuid();
BEGIN
    -- -------------------------------------------------------
    -- 1. Create auth users (trigger auto-creates user_profiles)
    -- -------------------------------------------------------
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        -- Buyer account
        (
            buyer_uuid,
            '00000000-0000-0000-0000-000000000000',
            'authenticated', 'authenticated',
            'acheteur@zehouse.fr',
            crypt('Zehouse2026!', gen_salt('bf', 10)),
            now(), now(), now(),
            jsonb_build_object('full_name', 'Marie Dupont', 'role', 'acheteur', 'avatar_url', 'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg'),
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
            false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
        ),
        -- Seller account
        (
            seller_uuid,
            '00000000-0000-0000-0000-000000000000',
            'authenticated', 'authenticated',
            'vendeur@zehouse.fr',
            crypt('Zehouse2026!', gen_salt('bf', 10)),
            now(), now(), now(),
            jsonb_build_object('full_name', 'Pierre Martin', 'role', 'vendeur', 'avatar_url', 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg'),
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
            false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
        ),
        -- Agent account
        (
            agent_uuid,
            '00000000-0000-0000-0000-000000000000',
            'authenticated', 'authenticated',
            'agent@zehouse.fr',
            crypt('Zehouse2026!', gen_salt('bf', 10)),
            now(), now(), now(),
            jsonb_build_object('full_name', 'Sophie Bernard', 'role', 'agent', 'avatar_url', 'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg'),
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
            false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
        )
    ON CONFLICT (id) DO NOTHING;

    -- -------------------------------------------------------
    -- 2. Update phone numbers in user_profiles (after trigger creates them)
    -- -------------------------------------------------------
    UPDATE public.user_profiles
    SET phone = '+33 6 12 34 56 78'
    WHERE email = 'acheteur@zehouse.fr';

    UPDATE public.user_profiles
    SET phone = '+33 6 98 76 54 32'
    WHERE email = 'vendeur@zehouse.fr';

    UPDATE public.user_profiles
    SET phone = '+33 6 55 44 33 22'
    WHERE email = 'agent@zehouse.fr';

    -- -------------------------------------------------------
    -- 3. Saved properties for buyer (Marie Dupont)
    -- -------------------------------------------------------
    INSERT INTO public.saved_properties (
        id, user_id, property_id, title, address, price, listing_type,
        surface, rooms, image_url, semantic_label, saved_at
    ) VALUES
        (
            gen_random_uuid(), buyer_uuid, 'p1',
            'Appartement Haussmannien',
            '12 Rue de la Paix, 75001 Paris',
            850000, 'sale', 87.0, 4,
            'https://img.rocket.new/generatedImages/rocket_gen_img_1a002677e-1772365142336.png',
            'Spacious Haussmann-style living room with parquet floors and tall windows overlooking Paris',
            now() - INTERVAL '3 days'
        ),
        (
            gen_random_uuid(), buyer_uuid, 'p5',
            'Duplex Vue Seine',
            '3 Quai de Grenelle, 75015 Paris',
            1680000, 'sale', 150.0, 5,
            'https://images.unsplash.com/photo-1587840441458-66457f848a2d',
            'Luxury duplex apartment with panoramic view of the Seine river and Eiffel Tower',
            now() - INTERVAL '1 day'
        ),
        (
            gen_random_uuid(), buyer_uuid, 'p2',
            'Studio Moderne Marais',
            '8 Rue des Rosiers, 75004 Paris',
            1450, 'rent', 44.0, 1,
            'https://img.rocket.new/generatedImages/rocket_gen_img_1186363d3-1768979392023.png',
            'Modern studio apartment with open kitchen and large windows in the Marais district',
            now() - INTERVAL '5 days'
        )
    ON CONFLICT (user_id, property_id) DO NOTHING;

    -- -------------------------------------------------------
    -- 4. Saved properties for agent (Sophie Bernard)
    -- -------------------------------------------------------
    INSERT INTO public.saved_properties (
        id, user_id, property_id, title, address, price, listing_type,
        surface, rooms, image_url, semantic_label, saved_at
    ) VALUES
        (
            gen_random_uuid(), agent_uuid, 'p7',
            'Hotel Boutique Montmartre',
            '18 Rue Lepic, 75018 Paris',
            3200000, 'sale', 400.0, 20,
            'https://img.rocket.new/generatedImages/rocket_gen_img_1562035cd-1772532988978.png',
            'Elegant boutique hotel facade with classic Parisian architecture and ornate balconies in Montmartre',
            now() - INTERVAL '2 days'
        ),
        (
            gen_random_uuid(), agent_uuid, 'p11',
            'Bureau Moderne La Defense',
            '1 Place de la Defense, 92800 Puteaux',
            3500, 'rent', 120.0, 4,
            'https://img.rocket.new/generatedImages/rocket_gen_img_1eb4180eb-1765300258586.png',
            'Modern open-plan office space with glass walls, workstations and city view at La Defense',
            now() - INTERVAL '4 days'
        )
    ON CONFLICT (user_id, property_id) DO NOTHING;

    -- -------------------------------------------------------
    -- 5. Demo conversation between buyer and agent
    -- -------------------------------------------------------
    INSERT INTO public.conversations (
        id, participant_one, participant_two,
        property_title, property_image_url, property_price,
        last_message, last_message_at, created_at
    ) VALUES (
        gen_random_uuid(),
        buyer_uuid,
        agent_uuid,
        'Appartement Haussmannien - 12 Rue de la Paix',
        'https://img.rocket.new/generatedImages/rocket_gen_img_1a002677e-1772365142336.png',
        '850 000 €',
        'Bonjour, je suis disponible pour une visite samedi matin.',
        now() - INTERVAL '2 hours',
        now() - INTERVAL '1 day'
    ) ON CONFLICT ON CONSTRAINT unique_conversation DO NOTHING;

    -- Demo conversation between seller and agent
    INSERT INTO public.conversations (
        id, participant_one, participant_two,
        property_title, property_image_url, property_price,
        last_message, last_message_at, created_at
    ) VALUES (
        gen_random_uuid(),
        seller_uuid,
        agent_uuid,
        'Maison avec Jardin - 45 Avenue du Parc',
        'https://img.rocket.new/generatedImages/rocket_gen_img_1086ff437-1773123732693.png',
        '1 250 000 €',
        'Le bien est disponible pour des visites du lundi au vendredi.',
        now() - INTERVAL '30 minutes',
        now() - INTERVAL '3 days'
    ) ON CONFLICT ON CONSTRAINT unique_conversation DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Test accounts creation error: %', SQLERRM;
END $$;
