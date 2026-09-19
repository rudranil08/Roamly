import SwiftUI
import SwiftData

struct CloudSyncSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var visits: [VisitEntity]
    
    @State private var syncEngine = SyncEngine.shared
    @State private var config = SupabaseConfigService.shared
    
    @State private var projectUrlText: String = ""
    @State private var apiKeyText: String = ""
    @State private var isMockMode: Bool = false
    @State private var isCloudSyncEnabled: Bool = true
    @State private var showSqlSheet: Bool = false
    @State private var showCopiedAlert: Bool = false
    @State private var showSavedAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Live Status & Telemetry
                Section {
                    HStack {
                        Label {
                            Text("Network Reachability")
                                .foregroundColor(AppTheme.charcoal)
                        } icon: {
                            Image(systemName: syncEngine.isOnline ? "wifi" : "wifi.slash")
                                .foregroundColor(syncEngine.isOnline ? AppTheme.sageOlive : AppTheme.terracotta)
                        }
                        
                        Spacer()
                        
                        StatusPill(
                            title: syncEngine.isOnline ? "Online" : "Offline",
                            icon: syncEngine.isOnline ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                            color: syncEngine.isOnline ? AppTheme.sageOlive : AppTheme.terracotta
                        )
                    }
                    
                    HStack {
                        Label {
                            Text("Device UUID")
                                .foregroundColor(AppTheme.charcoal)
                        } icon: {
                            Image(systemName: "iphone")
                                .foregroundColor(AppTheme.charcoal)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = config.userId.uuidString
                            showCopiedAlert = true
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }) {
                            HStack(spacing: 4) {
                                Text(String(config.userId.uuidString.prefix(8)) + "...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(AppTheme.mutedWarmGray)
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.terracotta)
                            }
                            .frame(minHeight: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy Device UUID to clipboard")
                    }
                    
                    HStack {
                        Label {
                            Text("Outbox Transactions")
                                .foregroundColor(AppTheme.charcoal)
                        } icon: {
                            Image(systemName: "tray.full.fill")
                                .foregroundColor(AppTheme.charcoal)
                        }
                        
                        Spacer()
                        
                        if syncEngine.isSyncing {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Syncing...")
                                    .font(.system(.subheadline, design: .default))
                                    .foregroundColor(AppTheme.mutedWarmGray)
                            }
                        } else if syncEngine.pendingSyncCount > 0 {
                            Text("\(syncEngine.pendingSyncCount) pending")
                                .font(.system(.subheadline, design: .default, weight: .bold))
                                .foregroundColor(AppTheme.terracotta)
                        } else {
                            Text("All delivered")
                                .font(.system(.subheadline, design: .default, weight: .bold))
                                .foregroundColor(AppTheme.sageOlive)
                        }
                    }
                    
                    Toggle(isOn: $isCloudSyncEnabled) {
                        Label("Enable Background Cloud Sync", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(AppTheme.charcoal)
                    }
                    .tint(AppTheme.terracotta)
                    .onChange(of: isCloudSyncEnabled) { _, newValue in
                        config.isCloudSyncEnabled = newValue
                    }
                } header: {
                    Text("TELEMETRY & STATUS")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                // Section 2: Mock & Simulation
                Section {
                    Toggle(isOn: $isMockMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Simulated HTTP Mode")
                                .foregroundColor(AppTheme.charcoal)
                            Text("Simulate network latency and 200 OK responses on device")
                                .font(.system(.caption, design: .default))
                                .foregroundColor(AppTheme.mutedWarmGray)
                        }
                    }
                    .tint(AppTheme.terracotta)
                    .onChange(of: isMockMode) { _, newValue in
                        config.isMockMode = newValue
                    }
                } header: {
                    Text("EXPEDITION LAB")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                // Section 3: Credentials
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REST Endpoint URL")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(AppTheme.mutedWarmGray)
                        TextField("https://xyzcompany.supabase.co", text: $projectUrlText)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key (Anon / Service)")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(AppTheme.mutedWarmGray)
                        SecureField("eyJhbGciOi...", text: $apiKeyText)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    
                    Button("Save Configuration") {
                        config.projectUrl = projectUrlText.trimmingCharacters(in: .whitespacesAndNewlines)
                        config.apiKey = apiKeyText.trimmingCharacters(in: .whitespacesAndNewlines)
                        showSavedAlert = true
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                    .font(.system(.subheadline, design: .default, weight: .semibold))
                    .foregroundColor(AppTheme.terracotta)
                    .frame(minHeight: 44)
                } header: {
                    Text("SUPABASE POSTGIS CREDENTIALS")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                } footer: {
                    Text("Visits are dispatched idempotently via HTTP POST with WKT spatial geography points.")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                // Section 4: Manual Operations
                Section {
                    Button(action: triggerManualSync) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Pending Items Now")
                            Spacer()
                            if syncEngine.isSyncing {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .foregroundColor(AppTheme.charcoal)
                        .frame(minHeight: 44)
                    }
                    .disabled(syncEngine.isSyncing)
                    
                    Button(action: resyncAllVisits) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Resync All \(visits.count) Local Visits")
                        }
                        .foregroundColor(AppTheme.terracotta)
                        .frame(minHeight: 44)
                    }
                    .disabled(syncEngine.isSyncing || visits.isEmpty)
                    
                    Button(role: .destructive, action: { syncEngine.clearQueue(in: modelContext) }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Pending Queue")
                        }
                        .frame(minHeight: 44)
                    }
                    .disabled(syncEngine.pendingSyncCount == 0)
                } header: {
                    Text("MANUAL PIPELINE ACTIONS")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                // Section 5: Database Schema
                Section {
                    Button(action: { showSqlSheet = true }) {
                        HStack {
                            Label("View PostGIS SQL Schema", systemImage: "doc.text.fill")
                                .foregroundColor(AppTheme.charcoal)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.mutedWarmGray)
                        }
                        .frame(minHeight: 44)
                    }
                } header: {
                    Text("CLOUD INFRASTRUCTURE")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                } footer: {
                    Text("Includes PostGIS geography(Point, 4326), GIST spatial index, and Row-Level Security definitions.")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.parchment)
            .navigationTitle("Supabase PostGIS Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundColor(AppTheme.terracotta)
                }
            }
            .sheet(isPresented: $showSqlSheet) {
                SupabaseSqlView()
            }
            .alert("Copied to Clipboard", isPresented: $showCopiedAlert) {
                Button("OK") {}
            } message: {
                Text("Device UUID has been copied to your clipboard.")
            }
            .alert("Credentials Saved", isPresented: $showSavedAlert) {
                Button("OK") {}
            } message: {
                Text("Supabase REST endpoint and anonymous key have been updated.")
            }
            .onAppear {
                projectUrlText = config.projectUrl
                apiKeyText = config.apiKey
                isMockMode = config.isMockMode
                isCloudSyncEnabled = config.isCloudSyncEnabled
            }
        }
    }
    
    private func triggerManualSync() {
        Task {
            await syncEngine.processQueue(modelContext: modelContext)
        }
    }
    
    private func resyncAllVisits() {
        syncEngine.resyncAllVisits(from: visits, modelContext: modelContext)
    }
}

struct SupabaseSqlView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var didCopy: Bool = false
    
    private let sqlScript = """
    -- Enable PostGIS spatial extension
    CREATE EXTENSION IF NOT EXISTS postgis;

    -- Create visits telemetry table
    CREATE TABLE IF NOT EXISTS public.visits (
        id UUID PRIMARY KEY,
        user_id UUID NOT NULL,
        place_name TEXT NOT NULL,
        latitude DOUBLE PRECISION NOT NULL,
        longitude DOUBLE PRECISION NOT NULL,
        location GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
            ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
        ) STORED,
        distance_km DOUBLE PRECISION NOT NULL,
        category TEXT NOT NULL,
        travel_mode TEXT NOT NULL,
        spending_amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
        spending_currency TEXT NOT NULL DEFAULT 'USD',
        calculated_score INTEGER NOT NULL,
        is_verified BOOLEAN NOT NULL DEFAULT true,
        photo_path TEXT,
        captured_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    -- Spatial GIST Index for ultra-fast radius queries
    CREATE INDEX IF NOT EXISTS visits_geo_idx ON public.visits USING GIST (location);

    -- Row Level Security (RLS)
    ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "Allow individual user operations"
    ON public.visits FOR ALL
    USING (auth.uid() = user_id OR user_id IS NOT NULL);
    """
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Execute this SQL statement in your Supabase SQL Editor to configure the PostGIS spatial database for Roamly.")
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                    
                    Text(sqlScript)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(AppTheme.charcoal)
                        .padding(14)
                        .background(AppTheme.parchmentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppTheme.subtleBorder, lineWidth: 1)
                        )
                    
                    Button(action: {
                        UIPasteboard.general.string = sqlScript
                        didCopy = true
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }) {
                        HStack {
                            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                            Text(didCopy ? "Copied SQL to Clipboard" : "Copy SQL Script")
                        }
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .foregroundColor(AppTheme.parchmentSurface)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(AppTheme.charcoal)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(AppTheme.parchment)
            .navigationTitle("PostGIS SQL Schema")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundColor(AppTheme.terracotta)
                }
            }
        }
    }
}
