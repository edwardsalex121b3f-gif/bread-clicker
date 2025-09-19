# 🍞 Bread Clicker - Supabase Setup Guide

## 📋 **What You Need to Access Your Supabase:**

1. **Supabase Project URL** - Found in your project settings
2. **Supabase Anon Key** - Found in your project API settings
3. **Supabase Service Role Key** - For admin operations (keep this secret!)

## 🗄️ **Database Schema Setup**

Run these SQL commands in your Supabase SQL Editor:

### 1. Create Tables

```sql
-- Users table with role system
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role INTEGER DEFAULT 0, -- 0 = user, 1 = admin
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_banned BOOLEAN DEFAULT FALSE,
  ban_reason TEXT,
  banned_at TIMESTAMP WITH TIME ZONE
);

-- Game saves table
CREATE TABLE game_saves (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  bread BIGINT DEFAULT 0,
  total_bread BIGINT DEFAULT 0,
  bread_per_click INTEGER DEFAULT 1,
  bread_per_second INTEGER DEFAULT 0,
  prestige_level INTEGER DEFAULT 0,
  prestige_multiplier DECIMAL DEFAULT 1.0,
  player_level INTEGER DEFAULT 1,
  experience BIGINT DEFAULT 0,
  upgrades JSONB DEFAULT '{}',
  shop_items JSONB DEFAULT '{}',
  achievements JSONB DEFAULT '[]',
  stats JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Events table
CREATE TABLE events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  event_type TEXT NOT NULL,
  value DECIMAL NOT NULL,
  duration_hours INTEGER NOT NULL,
  participants INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

-- Activity logs table
CREATE TABLE activity_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  details JSONB,
  ip_address INET,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Leaderboard view
CREATE VIEW leaderboard AS
SELECT 
  u.id,
  u.username,
  gs.total_bread,
  gs.prestige_level,
  gs.player_level,
  (gs.total_bread + gs.prestige_level * 1000000) as score
FROM users u
JOIN game_saves gs ON u.id = gs.user_id
WHERE u.is_banned = FALSE
ORDER BY score DESC
LIMIT 100;
```

### 2. Enable Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_saves ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

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
```

### 3. Create Functions for Role Checking

```sql
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
```

### 4. Create Admin Policies

```sql
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
```

### 5. Create Your First Admin User

```sql
-- Insert your first admin user (replace with your email)
-- You'll need to sign up first, then run this to make yourself admin
UPDATE users 
SET role = 1 
WHERE email = 'your-email@example.com';
```

## 🔧 **Configuration Steps**

### 1. Update supabase-config.js

Replace these values in `supabase-config.js`:

```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

### 2. Enable Email Authentication

In your Supabase dashboard:
1. Go to Authentication > Settings
2. Enable "Enable email confirmations" if you want email verification
3. Configure your site URL (e.g., `http://localhost:3000` for local development)

### 3. Set Up Email Templates (Optional)

In Authentication > Email Templates, you can customize:
- Confirm signup
- Reset password
- Magic link

## 🔐 **Security Notes**

1. **Never expose your service role key** in client-side code
2. **Use RLS policies** to secure your data
3. **Validate user roles** on both client and server side
4. **Log admin actions** for audit trails

## 🚀 **Deployment Notes**

1. **Update CORS settings** in Supabase for your domain
2. **Set up proper redirect URLs** for authentication
3. **Configure rate limiting** if needed
4. **Set up monitoring** for your database

## 📊 **Admin Panel Access**

- Only users with `role = 1` can access the admin panel
- Admin panel is hidden by default
- Click the logo to access admin panel (only visible to admins)
- All admin actions are logged in the activity_logs table

## 🆘 **Troubleshooting**

### Common Issues:

1. **"Invalid credentials"** - Check your Supabase URL and keys
2. **"Row Level Security"** - Make sure RLS policies are set up correctly
3. **"Permission denied"** - Check user roles and policies
4. **"Email not confirmed"** - Check email confirmation settings

### Getting Help:

1. Check Supabase logs in the dashboard
2. Use browser developer tools to see network errors
3. Verify your database schema matches the setup
4. Test with a simple query first

## 📝 **Next Steps After Setup**

1. Create your first admin account
2. Test the signup/login flow
3. Verify admin panel access
4. Test user management features
5. Set up your first event

---

**Remember**: Keep your Supabase keys secure and never commit them to public repositories!
