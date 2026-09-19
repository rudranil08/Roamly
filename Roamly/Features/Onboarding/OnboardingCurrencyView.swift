import SwiftUI

struct OnboardingCurrencyView: View {
    let onContinue: () -> Void
    
    @State private var selectedCode: String = UserSettingsService.shared.currencyCode
    @State private var searchText: String = ""
    
    private var filteredCurrencies: [CurrencyOption] {
        if searchText.isEmpty {
            return CurrencyOption.supportedCurrencies
        }
        return CurrencyOption.supportedCurrencies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.symbol.contains(searchText)
        }
    }
    
    private var currentOption: CurrencyOption {
        CurrencyOption.find(byCode: selectedCode) ?? CurrencyOption.defaultCurrency
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Choose Your Currency")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Roamly uses this currency when you record your travel spend.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 16)
            
            // Live Preview Card
            spendingPreviewCard
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search currency or code...", text: $searchText)
                    .font(.subheadline)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .roamlyInputStyle()
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            
            // Currency List
            List {
                ForEach(filteredCurrencies) { item in
                    currencyRow(item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCode = item.code
                        }
                        .listRowBackground(selectedCode == item.code ? AppTheme.baseGreenLight : AppTheme.cardBackground)
                }
            }
            .listStyle(.insetGrouped)
            
            // Bottom Action Bar
            VStack(spacing: 12) {
                Divider()
                
                Button(action: saveAndContinue) {
                    Text("Continue with \(currentOption.code) (\(currentOption.symbol))")
                }
                .buttonStyle(RoamlyPrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(AppTheme.cardBackground)
        }
    }
    
    // MARK: - Subviews
    
    private var spendingPreviewCard: some View {
        VStack(spacing: 6) {
            Text("SPENDING ENTRY PREVIEW")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .tracking(1.0)
            
            HStack(spacing: 8) {
                Text(CurrencyService.format(amount: 500.0, currencyCode: selectedCode))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.baseGreen)
                
                Text("(\(selectedCode))")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
            }
            
            Text("Recorded as \(currentOption.name) with ISO code \(selectedCode).")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .roamlyCard(padding: 12)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.baseGreen.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    private func currencyRow(_ option: CurrencyOption) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(selectedCode == option.code ? AppTheme.baseGreen : Color.secondary.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Text(option.symbol)
                    .font(.headline.bold())
                    .foregroundColor(selectedCode == option.code ? .white : .primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(option.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text("\(option.symbol) • ISO \(option.code)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(option.code)
                .font(.subheadline.monospaced().bold())
                .foregroundColor(selectedCode == option.code ? AppTheme.baseGreen : .secondary)
            
            if selectedCode == option.code {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.baseGreen)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func saveAndContinue() {
        UserSettingsService.shared.currencyCode = selectedCode
        onContinue()
    }
}
