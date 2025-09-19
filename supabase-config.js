// Supabase Configuration
const SUPABASE_URL = 'https://qxvymiorlyfwaykwglwe.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4dnltaW9ybHlmd2F5a3dnbHdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyMjk1NzcsImV4cCI6MjA3MzgwNTU3N30.Mk8NzyFuTT3QNNcuwIdjWM45w1OxC4sBI_ShntbYkfY';

// Initialize Supabase client (only if not already created)
if (typeof supabaseClient === 'undefined') {
    const { createClient } = supabase;
    window.supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

// Authentication functions
class AuthManager {
    static async signUp(email, password, username) {
        try {
            const { data, error } = await window.supabaseClient.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        username: username
                    }
                }
            });
            
            if (error) throw error;
            
            // Create user record in our users table with role 0 (regular user)
            if (data.user) {
                const { error: userError } = await window.supabaseClient
                    .from('users')
                    .insert({
                        id: data.user.id,
                        username: username,
                        email: email,
                        role: 0 // Default role for new users
                    });
                
                if (userError) {
                    console.error('Error creating user record:', userError);
                }
            }
            
            return { success: true, data };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async signIn(email, password) {
        try {
            const { data, error } = await window.supabaseClient.auth.signInWithPassword({
                email,
                password
            });
            
            if (error) throw error;
            return { success: true, data };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async signOut() {
        try {
            const { error } = await window.supabaseClient.auth.signOut();
            if (error) throw error;
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async getCurrentUser() {
        try {
            const { data: { user } } = await window.supabaseClient.auth.getUser();
            return user;
        } catch (error) {
            return null;
        }
    }

    static async getCurrentSession() {
        try {
            const { data: { session } } = await window.supabaseClient.auth.getSession();
            return session;
        } catch (error) {
            return null;
        }
    }
}

// Game data management
class GameDataManager {
    static async saveGameData(gameState) {
        try {
            const user = await AuthManager.getCurrentUser();
            if (!user) {
                // Fallback to localStorage if not authenticated
                localStorage.setItem('breadClickerSave', JSON.stringify(gameState));
                return { success: true, local: true };
            }

            const gameData = {
                user_id: user.id,
                bread: gameState.bread,
                total_bread: gameState.totalBread,
                bread_per_click: gameState.breadPerClick,
                bread_per_second: gameState.breadPerSecond,
                prestige_level: gameState.prestigeLevel,
                prestige_multiplier: gameState.prestigeMultiplier,
                player_level: gameState.playerLevel,
                experience: gameState.experience,
                upgrades: gameState.upgrades,
                shop_items: gameState.shop,
                achievements: Array.from(gameState.achievements),
                stats: gameState.stats,
                updated_at: new Date().toISOString()
            };

            // Check if save exists
            const { data: existingSave } = await supabaseClient
                .from('game_saves')
                .select('id')
                .eq('user_id', user.id)
                .single();

            let result;
            if (existingSave) {
                // Update existing save
                result = await supabaseClient
                    .from('game_saves')
                    .update(gameData)
                    .eq('user_id', user.id);
            } else {
                // Create new save
                result = await supabaseClient
                    .from('game_saves')
                    .insert(gameData);
            }

            if (result.error) throw result.error;
            return { success: true };
        } catch (error) {
            console.error('Error saving game data:', error);
            // Fallback to localStorage
            localStorage.setItem('breadClickerSave', JSON.stringify(gameState));
            return { success: true, local: true, error: error.message };
        }
    }

    static async loadGameData() {
        try {
            const user = await AuthManager.getCurrentUser();
            if (!user) {
                // Fallback to localStorage if not authenticated
                const saved = localStorage.getItem('breadClickerSave');
                return saved ? JSON.parse(saved) : null;
            }

            const { data, error } = await window.supabaseClient
                .from('game_saves')
                .select('*')
                .eq('user_id', user.id)
                .single();

            if (error && error.code !== 'PGRST116') throw error; // PGRST116 = no rows returned

            if (data) {
                return {
                    bread: data.bread,
                    totalBread: data.total_bread,
                    breadPerClick: data.bread_per_click,
                    breadPerSecond: data.bread_per_second,
                    prestigeLevel: data.prestige_level,
                    prestigeMultiplier: data.prestige_multiplier,
                    playerLevel: data.player_level,
                    experience: data.experience,
                    upgrades: data.upgrades,
                    shop: data.shop_items,
                    achievements: new Set(data.achievements),
                    stats: data.stats
                };
            }

            return null;
        } catch (error) {
            console.error('Error loading game data:', error);
            // Fallback to localStorage
            const saved = localStorage.getItem('breadClickerSave');
            return saved ? JSON.parse(saved) : null;
        }
    }

    static async getLeaderboard() {
        try {
            const { data, error } = await window.supabaseClient
                .from('leaderboard')
                .select('*')
                .limit(10);

            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('Error loading leaderboard:', error);
            return [];
        }
    }

    static async logActivity(action, details = {}) {
        try {
            const user = await AuthManager.getCurrentUser();
            if (!user) return;

            await supabaseClient
                .from('activity_logs')
                .insert({
                    user_id: user.id,
                    action: action,
                    details: details
                });
        } catch (error) {
            console.error('Error logging activity:', error);
        }
    }
}

// Admin functions
class AdminManager {
    static async adminLogin(username, password) {
        try {
            const { data, error } = await window.supabaseClient
                .from('admin_users')
                .select('*')
                .eq('username', username)
                .single();

            if (error) throw error;
            if (!data) throw new Error('Invalid credentials');

            // In a real app, you'd hash the password and compare
            // For now, we'll do a simple comparison (NOT SECURE FOR PRODUCTION)
            if (data.password_hash !== password) {
                throw new Error('Invalid credentials');
            }

            // Update last login
            await supabaseClient
                .from('admin_users')
                .update({ last_login: new Date().toISOString() })
                .eq('id', data.id);

            return { success: true, admin: data };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async getAllUsers() {
        try {
            const { data, error } = await window.supabaseClient
                .from('users')
                .select(`
                    *,
                    game_saves (
                        bread,
                        total_bread,
                        prestige_level,
                        player_level,
                        updated_at
                    )
                `);

            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('Error loading users:', error);
            return [];
        }
    }

    static async updateUser(userId, updates) {
        try {
            const { error } = await window.supabaseClient
                .from('users')
                .update(updates)
                .eq('id', userId);

            if (error) throw error;
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async updateUserGameData(userId, gameData) {
        try {
            const { error } = await window.supabaseClient
                .from('game_saves')
                .update(gameData)
                .eq('user_id', userId);

            if (error) throw error;
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async banUser(userId, reason) {
        try {
            const { error } = await window.supabaseClient
                .from('users')
                .update({
                    is_banned: true,
                    ban_reason: reason,
                    banned_at: new Date().toISOString()
                })
                .eq('id', userId);

            if (error) throw error;
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async unbanUser(userId) {
        try {
            const { error } = await window.supabaseClient
                .from('users')
                .update({
                    is_banned: false,
                    ban_reason: null,
                    banned_at: null
                })
                .eq('id', userId);

            if (error) throw error;
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async createEvent(eventData) {
        try {
            const { data, error } = await window.supabaseClient
                .from('events')
                .insert(eventData)
                .select()
                .single();

            if (error) throw error;
            return { success: true, event: data };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async getEvents() {
        try {
            const { data, error } = await window.supabaseClient
                .from('events')
                .select('*')
                .order('created_at', { ascending: false });

            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('Error loading events:', error);
            return [];
        }
    }

    static async endEvent(eventId) {
        try {
            const { error } = await window.supabaseClient
                .from('events')
                .update({ is_active: false })
                .eq('id', eventId);

            if (error) throw error;
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    static async getActivityLogs(limit = 50) {
        try {
            const { data, error } = await window.supabaseClient
                .from('activity_logs')
                .select(`
                    *,
                    users (username),
                    admin_users (username)
                `)
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) throw error;
            return data || [];
        } catch (error) {
            console.error('Error loading activity logs:', error);
            return [];
        }
    }
}

// Export for use in other files
window.AuthManager = AuthManager;
window.GameDataManager = GameDataManager;
window.AdminManager = AdminManager;
window.supabaseClient = supabaseClient;
