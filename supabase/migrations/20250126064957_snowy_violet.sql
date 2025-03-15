/*
  # Initial Schema for Magical Reading Competition

  1. New Tables
    - `profiles`
      - User profile information including reading stats and house assignment
    - `books`
      - Book database with titles, authors, and metadata
    - `reading_logs`
      - User reading activity tracking
    - `houses`
      - House information and statistics
    
  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create houses table
CREATE TABLE houses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  primary_color TEXT NOT NULL,
  secondary_color TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  facebook_link TEXT,
  avg_pages_monthly INTEGER NOT NULL,
  current_house_id UUID REFERENCES houses(id),
  total_pages_read INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create books table
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  cover_url TEXT,
  summary TEXT,
  pages INTEGER NOT NULL,
  genre TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(title, author)
);

-- Create reading_logs table
CREATE TABLE reading_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) NOT NULL,
  book_id UUID REFERENCES books(id) NOT NULL,
  pages_read INTEGER NOT NULL,
  rating DECIMAL(3,1) CHECK (rating >= 0 AND rating <= 5),
  review TEXT,
  read_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Insert house data
INSERT INTO houses (name, primary_color, secondary_color) VALUES
  ('Gryffindor', '#740001', '#D3A625'),
  ('Slytherin', '#1A472A', '#2A623D'),
  ('Ravenclaw', '#0E1A40', '#946B2D'),
  ('Hufflepuff', '#FFD800', '#000000');

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE houses ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Books policies
CREATE POLICY "Books are viewable by everyone"
  ON books FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert books"
  ON books FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update books they created"
  ON books FOR UPDATE
  USING (auth.uid() = created_by);

-- Reading logs policies
CREATE POLICY "Users can view their own reading logs"
  ON reading_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own reading logs"
  ON reading_logs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reading logs"
  ON reading_logs FOR UPDATE
  USING (auth.uid() = user_id);

-- Houses policies
CREATE POLICY "Houses are viewable by everyone"
  ON houses FOR SELECT
  USING (true);

-- Functions
CREATE OR REPLACE FUNCTION assign_house(pages_per_month INTEGER)
RETURNS UUID AS $$
DECLARE
  house_id UUID;
  total_users INTEGER;
  house_distribution JSONB;
BEGIN
  -- Get current distribution
  SELECT 
    jsonb_object_agg(current_house_id, count(*))
  INTO house_distribution
  FROM profiles
  WHERE current_house_id IS NOT NULL
  GROUP BY current_house_id;

  -- Find house with least members
  SELECT id INTO house_id
  FROM houses
  WHERE id NOT IN (SELECT jsonb_object_keys(house_distribution)::UUID)
  LIMIT 1;

  IF house_id IS NULL THEN
    SELECT id INTO house_id
    FROM houses
    WHERE id::TEXT = (
      SELECT key
      FROM jsonb_each(house_distribution)
      ORDER BY value::INTEGER ASC
      LIMIT 1
    );
  END IF;

  RETURN house_id;
END;
$$ LANGUAGE plpgsql;