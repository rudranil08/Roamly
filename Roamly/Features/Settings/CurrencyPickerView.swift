import SwiftUI

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
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
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredCurrencies) { item in
                        Button(action: {
                            UISelectionFeedbackGenerator().selectionChanged()
                            selectedCode = item.code
                            UserSettingsService.shared.updateCurrency(to: item.code)
                            dismiss()
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(selectedCode == item.code ? AppTheme.terracotta : AppTheme.parchment)
                                        .frame(width: 36, height: 36)
                                    
                                    Text(item.symbol)
                                        .font(.system(.subheadline, design: .default, weight: .bold))
                                        .foregroundColor(selectedCode == item.code ? .white : AppTheme.charcoal)
                                }
                                .accessibilityHidden(true)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(.body, design: .default, weight: .medium))
                                        .foregroundColor(AppTheme.charcoal)
                                    Text(item.code)
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(AppTheme.mutedWarmGray)
                                }
                                
                                Spacer()
                                
                                if selectedCode == item.code {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(AppTheme.terracotta)
                                }
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(item.name), \(item.code), symbol \(item.symbol)")
                        .accessibilityAddTraits(selectedCode == item.code ? [.isButton, .isSelected] : [.isButton])
                        .accessibilityHint("Double tap to select \(item.name) as default currency")
                    }
                } header: {
                    Text("SELECT DEFAULT CURRENCY")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                } footer: {
                    Text("Changing your default currency applies to future journeys. Past logs retain their original currency.")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.parchment)
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search currencies...")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundColor(AppTheme.terracotta)
                }
            }
        }
    }
}
