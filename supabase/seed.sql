-- REXAM: Comprehensive Seed Data (supabase/seed.sql)
-- Note: All dates are for demonstration purposes and clearly labelled as such.

-- 1. SEED ORGANISATIONS
INSERT INTO public.organisations (id, name, short_name, organisation_type, parent_ministry, website_url)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Union Public Service Commission', 'UPSC', 'Central Government', 'Department of Personnel and Training (DoPT)', 'https://upsc.gov.in'),
    ('a0000000-0000-0000-0000-000000000002', 'Indian Space Research Organisation', 'ISRO', 'PSU', 'Department of Space', 'https://isro.gov.in'),
    ('a0000000-0000-0000-0000-000000000003', 'Defence Research and Development Organisation', 'DRDO', 'Defence', 'Ministry of Defence', 'https://drdo.gov.in'),
    ('a0000000-0000-0000-0000-000000000004', 'State Bank of India', 'SBI', 'PSU', 'Ministry of Finance', 'https://sbi.co.in'),
    ('a0000000-0000-0000-0000-000000000005', 'National PMRF Coordination Committee', 'PMRF', 'University', 'Ministry of Education', 'https://pmrf.in'),
    ('a0000000-0000-0000-0000-000000000006', 'Indian Oil Corporation Limited', 'IOCL', 'PSU', 'Ministry of Petroleum and Natural Gas', 'https://iocl.com')
ON CONFLICT (name) DO NOTHING;

-- 2. SEED SOURCES
INSERT INTO public.sources (id, organisation_id, name, source_type, base_url, crawler_adapter, is_active, scrape_interval_hours)
VALUES
    ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'UPSC Active Examinations Portal', 'html', 'https://upsc.gov.in/examinations/active-examinations', 'upsc', true, 12),
    ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'ISRO ICRB Recruitment Notice Board', 'html', 'https://apps.isac.gov.in/icrb-2026', 'isro', true, 24),
    ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003', 'DRDO RAC Recruitment Notice Portal', 'html', 'https://rac.gov.in', 'drdo', true, 24)
ON CONFLICT (base_url) DO NOTHING;

-- 3. SEED EXAMINATIONS
INSERT INTO public.examinations (
    id, organisation_id, source_id, name, slug, category, status,
    overview, vacancies, salary_or_pay_scale, location,
    official_notification_url, official_application_url, source_url,
    last_verified_at, is_official_source, is_confirmed, is_central_government
)
VALUES
    (
        'c0000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000001',
        'b0000000-0000-0000-0000-000000000001',
        'Civil Services Examination (Preliminary) 2026',
        'upsc-cse-prelims-2026',
        'Government Recruitment',
        'published',
        'Annual premier competitive examination conducted by UPSC to recruit officers into IAS, IPS, IFS and Central Services Group A & B.',
        1056,
        'Level 10 of 7th CPC (₹56,100 to ₹1,77,500 base pay)',
        'All India Cadre Allocation',
        'https://upsc.gov.in/sites/default/files/ExamNotice_CSE_2026.pdf',
        'https://upsconline.nic.in',
        'https://upsc.gov.in',
        TIMEZONE('utc', NOW()),
        true, true, true
    ),
    (
        'c0000000-0000-0000-0000-000000000002',
        'a0000000-0000-0000-0000-000000000002',
        'b0000000-0000-0000-0000-000000000002',
        'Recruitment of Scientist/Engineer "SC" (CS / Mechanical / Electronics)',
        'isro-scientist-engineer-sc-2026',
        'PSU Recruitment',
        'published',
        'ISRO Centralised Recruitment Board invites applications for Group A Gazetted Scientist posts in Bengaluru, VSSC, and URSC.',
        320,
        'Level 10 (Gross Emoluments ~₹92,000/month)',
        'Bengaluru, Thiruvananthapuram, Sriharikota',
        'https://www.isro.gov.in/media_isro/pdf/recruitment/ICRB_01_2026.pdf',
        'https://apps.isac.gov.in/icrb-2026',
        'https://isro.gov.in',
        TIMEZONE('utc', NOW()),
        true, true, true
    ),
    (
        'c0000000-0000-0000-0000-000000000003',
        'a0000000-0000-0000-0000-000000000003',
        'b0000000-0000-0000-0000-000000000003',
        'Recruitment of Scientist "B" via Valid GATE Score (RAC Advt 148)',
        'drdo-scientist-b-gate-2026',
        'Government Recruitment',
        'published',
        'DRDO RAC invites applications for 204 Scientist "B" positions in strategic aerospace, defense electronic, and computing divisions.',
        204,
        'Level 10 (Basic ₹56,100, gross ~₹95,000/month)',
        'Pan-India DRDO Laboratories',
        'https://rac.gov.in/download/advt_148_scientist_b.pdf',
        'https://rac.gov.in',
        'https://rac.gov.in',
        TIMEZONE('utc', NOW()),
        true, true, true
    )
ON CONFLICT (slug) DO NOTHING;

-- 4. SEED EXAMINATION DATES (Labelled Demonstration Data)
INSERT INTO public.examination_dates (
    examination_id, notification_date, application_opening_date,
    application_closing_date, fee_payment_deadline, admit_card_release_date,
    examination_start_date, is_tentative
)
VALUES
    (
        'c0000000-0000-0000-0000-000000000001',
        '2026-02-14',
        '2026-02-14 10:00:00+00',
        '2026-03-06 12:30:00+00',
        '2026-03-06 12:30:00+00',
        '2026-05-10',
        '2026-05-25',
        false
    ),
    (
        'c0000000-0000-0000-0000-000000000002',
        '2026-02-20',
        '2026-02-22 00:00:00+00',
        '2026-03-15 18:29:59+00',
        '2026-03-15 18:29:59+00',
        '2026-04-28',
        '2026-05-10',
        false
    ),
    (
        'c0000000-0000-0000-0000-000000000003',
        '2026-02-28',
        '2026-02-28 00:00:00+00',
        '2026-03-29 11:30:00+00',
        '2026-03-29 11:30:00+00',
        '2026-04-15',
        '2026-04-30',
        true
    )
ON CONFLICT (examination_id) DO NOTHING;

-- 5. SEED ELIGIBILITY RULES
INSERT INTO public.eligibility_rules (
    examination_id, min_age, max_age, age_cutoff_date,
    category_age_relaxations, educational_qualifications, eligible_branches,
    min_percentage, nationality, fee_general, fee_exemptions, evidence_page_number, extracted_rule_text
)
VALUES
    (
        'c0000000-0000-0000-0000-000000000001',
        21, 32, '2026-08-01',
        '{"General": "32 years, 6 attempts", "OBC-NCL": "35 years (3 years relaxation, 9 attempts)", "SC/ST": "37 years (5 years relaxation, unlimited attempts)", "PwBD": "42 years (10 years relaxation)"}'::jsonb,
        ARRAY['Bachelor’s Degree in any discipline from recognized University'],
        ARRAY['All Disciplines'],
        NULL,
        'Citizen of India',
        100.00,
        'Female candidates, SC, ST and PwBD are fully exempted from payment of fee',
        4,
        'Clause 3(b) Age Limits: A candidate must have attained the age of 21 years and must not have attained the age of 32 years on the 1st of August 2026.'
    ),
    (
        'c0000000-0000-0000-0000-000000000002',
        18, 28, '2026-03-15',
        '{"General": "28 years", "OBC-NCL": "31 years (3 years)", "SC/ST": "33 years (5 years)", "PwBD": "38 years (10 years)"}'::jsonb,
        ARRAY['B.E. / B.Tech or equivalent in relevant branch with First Class'],
        ARRAY['Computer Science & Engineering', 'Information Technology', 'Mechanical Engineering', 'Electronics & Communication'],
        65.00,
        'Citizen of India',
        250.00,
        'All Women, SC, ST, PwBD and Ex-Servicemen exempted',
        2,
        'Clause 2.1: Minimum 65% aggregate marks or 6.84 CGPA on a 10-point scale.'
    ),
    (
        'c0000000-0000-0000-0000-000000000003',
        21, 28, '2026-03-29',
        '{"General/EWS": "28 years", "OBC-NCL": "31 years", "SC/ST": "33 years", "PwBD": "38 years"}'::jsonb,
        ARRAY['First Class Bachelor’s Degree in Engineering with Valid GATE Score'],
        ARRAY['Computer Science & Engineering', 'Mechanical Engineering', 'Electronics & Communication', 'Electrical Engineering'],
        60.00,
        'Citizen of India',
        100.00,
        'SC/ST/PwBD and Women candidates exempted',
        1,
        'Advt 148: Candidates must possess valid GATE scorecard in relevant discipline code.'
    )
ON CONFLICT (examination_id) DO NOTHING;

