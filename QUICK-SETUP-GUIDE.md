# 🍞 Bread Clicker - Quick Setup Guide

## ✅ **Your Supabase Credentials (Already Configured):**
- **Project URL:** `https://qxvymiorlyfwaykwglwe.supabase.co`
- **Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4dnltaW9ybHlmd2F5a3dnbHdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyMjk1NzcsImV4cCI6MjA3MzgwNTU3N30.Mk8NzyFuTT3QNNcuwIdjWM45w1OxC4sBI_ShntbYkfY`
- **Service Role Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4dnltaW9ybHlmd2F5a3dnbHdlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODIyOTU3NywiZXhwIjoyMDczODA1NTc3fQ.w5_c4NcCezdsOJZ2S-BD8MAOWV6d_NvpUhgjQSgvuqs`
- **Project Password:** `8D793HNHD2312!q`

## 🚀 **Step-by-Step Setup:**

### **1. Set Up Database (5 minutes)**
1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Open your project: `qxvymiorlyfwaykwglwe`
3. Go to **SQL Editor** (left sidebar)
4. Copy and paste the entire contents of `supabase-setup.sql`
5. Click **Run** to execute all the SQL commands
6. ✅ Database is now set up!

### **2. Test the Game (2 minutes)**
1. Open `index.html` in your browser
2. Click **"Play Game"**
3. Click **"Login/Register"**
4. Create a new account
5. ✅ Game should work!

### **3. Make Yourself Admin (1 minute)**
1. Go to your Supabase dashboard
2. Go to **Table Editor** → **users**
3. Find your account (by email)
4. Change the `role` column from `0` to `1`
5. Save the changes
6. ✅ You're now an admin!

### **4. Test Admin Access (1 minute)**
1. Refresh your game page
2. Login with your account
3. Look at the logo - it should have a crown 👑
4. Click the logo
5. ✅ Admin panel should open!

## 🎮 **How to Play:**

### **For Regular Users:**
- Visit `index.html`
- Sign up or login
- Click the bread to earn points
- Buy upgrades and shop items
- Prestige when you reach 1M bread

### **For Admins:**
- Everything above, PLUS:
- Click the logo (with crown) to access admin panel
- Manage users, events, and game economy
- View analytics and security logs

## 🔧 **File Structure:**
```
Bread Clicker/
├── index.html              # Landing page
├── login.html              # Login page
├── signup.html             # Signup page
├── index-supabase.html     # Main game (with Supabase)
├── admin-supabase.html     # Admin panel
├── supabase-config.js      # Supabase configuration
├── supabase-setup.sql      # Database setup SQL
└── QUICK-SETUP-GUIDE.md    # This file
```

## 🆘 **Troubleshooting:**

### **"Invalid credentials" error:**
- Check that you copied the SQL correctly
- Make sure all tables were created

### **"Access denied" in admin panel:**
- Make sure your user role is set to `1` in the database
- Refresh the page after changing your role

### **Game not saving:**
- Check browser console for errors
- Make sure you're logged in

### **Can't see admin panel:**
- Make sure your role is `1` in the users table
- Look for the crown icon on the logo

## 🎯 **You're All Set!**

Your Bread Clicker game is now fully functional with:
- ✅ User authentication
- ✅ Role-based access control
- ✅ Admin panel
- ✅ Database persistence
- ✅ Security policies

**Have fun baking bread!** 🍞
