export interface UserProfile {
  id: string;
  username: string;
  email: string;
  facebook_link: string | null;
  avg_pages_monthly: number;
  current_house_id: string;
  total_pages_read: number;
  created_at: string;
  updated_at: string;
}

export interface Book {
  id: string;
  title: string;
  author: string;
  cover_url: string | null;
  summary: string | null;
  pages: number;
  genre: string | null;
  created_by: string;
  created_at: string;
}

export interface ReadingLog {
  id: string;
  user_id: string;
  book_id: string;
  pages_read: number;
  rating: number;
  review: string | null;
  read_date: string;
  created_at: string;
}

export interface House {
  id: string;
  name: string;
  primary_color: string;
  secondary_color: string;
  created_at: string;
}