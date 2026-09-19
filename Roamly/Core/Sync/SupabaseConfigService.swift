import Foundation
import Observation

@Observable
public final class SupabaseConfigService {
    public static let shared = SupabaseConfigService()
    
    private let urlKey = "roamly_supabase_url"
    private let anonKey = "roamly_supabase_anon_key"
    private let userIdKey = "roamly_device_user_id"
    private let syncEnabledKey = "roamly_cloud_sync_enabled"
    private let mockModeKey = "roamly_mock_sync_mode"
    
    // Default demo/sandbox credentials
    public static let defaultUrl = "https://roamly-demo.supabase.co"
    public static let defaultAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.roamly-demo-token"
    
    public var projectUrl: String {
        didSet {
            UserDefaults.standard.set(projectUrl, forKey: urlKey)
        }
    }
    
    public var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: anonKey)
        }
    }
    
    public var isCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCloudSyncEnabled, forKey: syncEnabledKey)
        }
    }
    
    public var isMockMode: Bool {
        didSet {
            UserDefaults.standard.set(isMockMode, forKey: mockModeKey)
        }
    }
    
    public var userId: UUID {
        didSet {
            UserDefaults.standard.set(userId.uuidString, forKey: userIdKey)
        }
    }
    
    private init() {
        self.projectUrl = UserDefaults.standard.string(forKey: urlKey) ?? Self.defaultUrl
        self.apiKey = UserDefaults.standard.string(forKey: anonKey) ?? Self.defaultAnonKey
        self.isCloudSyncEnabled = UserDefaults.standard.object(forKey: syncEnabledKey) as? Bool ?? true
        self.isMockMode = UserDefaults.standard.object(forKey: mockModeKey) as? Bool ?? true
        
        if let storedId = UserDefaults.standard.string(forKey: userIdKey), let uid = UUID(uuidString: storedId) {
            self.userId = uid
        } else {
            let newId = UUID()
            self.userId = newId
            UserDefaults.standard.set(newId.uuidString, forKey: userIdKey)
        }
    }
    
    public func resetToDefaults() {
        self.projectUrl = Self.defaultUrl
        self.apiKey = Self.defaultAnonKey
        self.isCloudSyncEnabled = true
        self.isMockMode = true
    }
    
    public var isConfiguredWithCustomEndpoint: Bool {
        !projectUrl.isEmpty &&
        projectUrl != Self.defaultUrl &&
        !apiKey.isEmpty &&
        apiKey != Self.defaultAnonKey
    }
    
    public static let postgisSchemaSQL = """
    -- ==========================================
    -- ROAMLY POSTGIS CLOUD SCHEMA MIGRATION
    -- ==========================================
    
    -- 1. Enable PostGIS Extension
    create extension if not exists postgis;
    
    -- 2. Create Visits Table with Native PostGIS Geography
    create table if not exists public.visits (
        id uuid primary key,
        user_id uuid not null,
        place_name text not null,
        category text not null,
        travel_mode text not null,
        spending_amount numeric default 0,
        spending_currency text default 'USD',
        photo_hash text,
        calculated_score integer not null,
        distance_km numeric default 0,
        is_verified boolean default true,
        location geography(Point, 4326) not null,
        latitude double precision not null,
        longitude double precision not null,
        captured_at timestamptz not null,
        synced_at timestamptz default now()
    );
    
    -- 3. Create High-Performance GIST Spatial Index
    create index if not exists visits_location_gist_idx 
        on public.visits using gist(location);
        
    -- 4. Create User Lookup Index
    create index if not exists visits_user_id_idx 
        on public.visits(user_id);
        
    -- 5. Row Level Security & Public API Policies
    alter table public.visits enable row level security;
    
    create policy "Allow idempotent upserts from authenticated and anon clients"
        on public.visits
        for all
        using (true)
        with check (true);
    """
}
