-- ========================================
-- BREAD CLICKER - SUPABASE DATABASE SETUP
-- ========================================
-- Run this SQL in your Supabase SQL Editor
-- Project URL: https://qxvymiorlyfwaykwglwe.supabase.co
-- ========================================

-- 1. CREATE TABLES
-- ========================================

-- Users table with role system
-- This table stores all user accounts and their roles
-- role: 0 = regular user, 1 = admin
-- is_banned: TRUE means user is banned from the game
-- ban_reason: Reason for the ban (optional)
-- banned_at: When the user was banned (optional)
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY, -- Unique user ID
  username TEXT UNIQUE NOT NULL, -- Display name (3-20 characters)
  email TEXT UNIQUE NOT NULL, -- Login email address
  role INTEGER DEFAULT 0, -- 0 = user, 1 = admin
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- When account was created
  last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Last login time
  is_banned BOOLEAN DEFAULT FALSE, -- Is user banned?
  ban_reason TEXT, -- Why was user banned?
  banned_at TIMESTAMP WITH TIME ZONE -- When was user banned?
);

-- Game saves table
-- This table stores each user's game progress and statistics
-- Each user has one game save record that gets updated as they play
-- JSONB fields store complex data like upgrades and achievements
CREATE TABLE game_saves (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY, -- Unique save ID
  user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- Links to users table
  bread BIGINT DEFAULT 0, -- Current bread count
  total_bread BIGINT DEFAULT 0, -- Total bread ever earned
  bread_per_click INTEGER DEFAULT 1, -- Bread earned per click
  bread_per_second INTEGER DEFAULT 0, -- Auto bread production per second
  prestige_level INTEGER DEFAULT 0, -- How many times user has prestiged
  prestige_multiplier DECIMAL DEFAULT 1.0, -- Permanent multiplier from prestige
  player_level INTEGER DEFAULT 1, -- Player level (based on experience)
  experience BIGINT DEFAULT 0, -- Total experience points earned
  upgrades JSONB DEFAULT '{}', -- Click and auto upgrades purchased
  shop_items JSONB DEFAULT '{}', -- Special bread items owned
  achievements JSONB DEFAULT '[]', -- List of unlocked achievements
  stats JSONB DEFAULT '{}', -- Additional statistics (clicks, time played, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- When save was created
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() -- Last save update
);

-- Events table
-- This table stores special game events that affect all players
-- Events can be multipliers, bonuses, or special game modes
-- Admins can create and manage events through the admin panel
CREATE TABLE events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY, -- Unique event ID
  name TEXT NOT NULL, -- Event name (e.g., "Double Bread Day")
  event_type TEXT NOT NULL, -- Type: multiplier, bonus, discount, special
  value DECIMAL NOT NULL, -- Event value (e.g., 2.0 for 2x multiplier)
  duration_hours INTEGER NOT NULL, -- How long event lasts (in hours)
  participants INTEGER DEFAULT 0, -- How many players participated
  is_active BOOLEAN DEFAULT TRUE, -- Is event currently active?
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- When event was created
  expires_at TIMESTAMP WITH TIME ZONE -- When event expires
);

-- Activity logs table
-- This table logs all important user and admin actions
-- Used for security monitoring, analytics, and audit trails
-- Helps track suspicious activity and admin actions
CREATE TABLE activity_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY, -- Unique log entry ID
  user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- User who performed action (can be NULL for system actions)
  action TEXT NOT NULL, -- What action was performed (e.g., "bread_click", "admin_login")
  details JSONB, -- Additional details about the action (JSON format)
  ip_address INET, -- IP address of the user (for security)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() -- When action occurred
);

-- 2. CREATE VIEWS
-- ========================================

-- Leaderboard view
-- This view creates a ranked list of top players
-- Combines users and game_saves tables to show player rankings
-- Score calculation: total_bread + (prestige_level * 1,000,000)
-- Only shows non-banned users, limited to top 100
CREATE VIEW leaderboard AS
SELECT 
  u.id, -- User ID
  u.username, -- Player name
  gs.total_bread, -- Total bread earned
  gs.prestige_level, -- How many prestiges completed
  gs.player_level, -- Current player level
  (gs.total_bread + gs.prestige_level * 1000000) as score -- Calculated ranking score
FROM users u
JOIN game_saves gs ON u.id = gs.user_id
WHERE u.is_banned = FALSE -- Only show active players
ORDER BY score DESC -- Highest scores first
LIMIT 100; -- Top 100 players only

-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ========================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_saves ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- 4. CREATE SECURITY POLICIES
-- ========================================

-- Users can only see their own data
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Game saves policies
CREATE POLICY "Users can view own saves" ON game_saves
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own saves" ON game_saves
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own saves" ON game_saves
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Events are public read
CREATE POLICY "Events are viewable by all" ON events
  FOR SELECT USING (true);

-- Activity logs are public read
CREATE POLICY "Activity logs are viewable by all" ON activity_logs
  FOR SELECT USING (true);

-- 5. CREATE FUNCTIONS FOR ROLE CHECKING
-- ========================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT role FROM users 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CREATE ADMIN POLICIES
-- ========================================

-- Admin policies for users table
CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all users" ON users
  FOR UPDATE USING (is_admin());

-- Admin policies for game_saves
CREATE POLICY "Admins can view all saves" ON game_saves
  FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all saves" ON game_saves
  FOR UPDATE USING (is_admin());

-- Admin policies for events
CREATE POLICY "Admins can manage events" ON events
  FOR ALL USING (is_admin());

-- Admin policies for activity_logs
CREATE POLICY "Admins can manage activity logs" ON activity_logs
  FOR ALL USING (is_admin());

-- 7. CREATE INDEXES FOR PERFORMANCE
-- ========================================

-- Index on users table
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_banned ON users(is_banned);

-- Index on game_saves table
CREATE INDEX idx_game_saves_user_id ON game_saves(user_id);
CREATE INDEX idx_game_saves_total_bread ON game_saves(total_bread);
CREATE INDEX idx_game_saves_prestige ON game_saves(prestige_level);

-- Index on events table
CREATE INDEX idx_events_active ON events(is_active);
CREATE INDEX idx_events_expires ON events(expires_at);

-- Index on activity_logs table
CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);

-- 8. CREATE TRIGGERS
-- ========================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to game_saves table
CREATE TRIGGER update_game_saves_updated_at
    BEFORE UPDATE ON game_saves
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 9. INSERT SAMPLE DATA (OPTIONAL)
-- ========================================

-- Insert a sample event
INSERT INTO events (name, event_type, value, duration_hours, is_active, expires_at)
VALUES (
  'Welcome Event',
  'multiplier',
  2.0,
  168, -- 1 week
  true,
  NOW() + INTERVAL '7 days'
);

-- 10. GRANT PERMISSIONS
-- ========================================

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Grant permissions to anon users for public data
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON events TO anon;
GRANT SELECT ON activity_logs TO anon;
GRANT SELECT ON leaderboard TO anon;

-- ========================================
-- SETUP COMPLETE!
-- ========================================
-- 
-- Next steps:
-- 1. Sign up for an account in your game
-- 2. Find your user ID in the users table
-- 3. Update your role to 1 to become an admin:
--    UPDATE users SET role = 1 WHERE email = 'your-email@example.com';
-- 
-- TABLE DESCRIPTIONS:
-- ========================================
-- users: All user accounts with roles and ban status
-- game_saves: Each user's game progress and statistics
-- events: Special game events created by admins
-- activity_logs: Security and audit logs for all actions
-- leaderboard: View showing top 100 players ranked by score
-- 
-- IMPORTANT NOTES:
-- ========================================
-- - role = 0: Regular user (default for new signups)
-- - role = 1: Admin (can access admin panel via logo click)
-- - is_banned = TRUE: User is banned from the game
-- - JSONB fields store complex data like upgrades and achievements
-- - All tables have Row Level Security (RLS) enabled
-- - Admin functions check user roles for access control
-- 
-- Your Supabase project is now ready for Bread Clicker! 🍞
-- ========================================
