-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS payments (
  id bigint generated always as identity primary key,
  transaction_id text unique not null,
  amount numeric default 10,
  verified boolean default false,
  created_at timestamptz default now()
);

-- Enable RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read (to verify their transaction)
CREATE POLICY "allow_read" ON payments FOR SELECT USING (true);

-- Allow anyone to insert (user submits their transaction ID)
CREATE POLICY "allow_insert" ON payments FOR INSERT WITH CHECK (true);
