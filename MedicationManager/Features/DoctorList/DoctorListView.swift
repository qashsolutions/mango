import SwiftUI
import Contacts

struct DoctorListView: View {
    @State private var viewModel = DoctorListViewModel()
    // Use singleton directly - it manages its own lifecycle with @Observable
    private let navigationManager = NavigationManager.shared
    @State private var searchText: String = ""
    @State private var showingAddOptions: Bool = false
    @State private var showingContactImport: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    LoadingState(message: AppStrings.Doctors.loadingDoctors)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.doctors.isEmpty && searchText.isEmpty {
                    DoctorEmptyState(onAddDoctor: {
                        showingAddOptions = true
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    DoctorListContent(
                        doctors: filteredDoctors,
                        searchText: $searchText,
                        onDoctorTap: { doctor in
                            navigationManager.navigate(to: .doctorDetail(id: doctor.id))
                        },
                        onEditDoctor: { doctor in
                            navigationManager.presentSheet(.editDoctor(id: doctor.id))
                        },
                        onContactDoctor: { doctor in
                            Task {
                                await viewModel.contactDoctor(doctor)
                            }
                        }
                    )
                }
            }
            .navigationTitle(AppStrings.Tabs.doctorList)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: AppStrings.Doctors.searchDoctors)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        SyncActionButton()
                        
                        Button(action: { showingAddOptions = true }) {
                            Image(systemName: AppIcons.plus)
                                .font(AppTheme.Typography.callout)
                        }
                    }
                }
            }
            .confirmationDialog(AppStrings.Doctors.addDoctor, isPresented: $showingAddOptions) {
                Button(AppStrings.Doctors.addManually) {
                    navigationManager.presentSheet(.addDoctor(contact: nil))
                }
                
                Button(AppStrings.Doctors.importFromContacts) {
                    showingContactImport = true
                }
                
                Button(AppStrings.Common.cancel, role: .cancel) {}
            }
            .sheet(isPresented: $showingContactImport) {
                ContactImportView { contact, specialty in
                    Task {
                        await viewModel.importDoctor(from: contact, specialty: specialty)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.error.map { AlertItem.fromError($0) } },
                set: { _ in viewModel.clearError() }
            )) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text(AppStrings.Common.ok))
                )
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    private var filteredDoctors: [DoctorModel] {
        if searchText.isEmpty {
            return viewModel.doctors
        } else {
            return viewModel.doctors.filter { doctor in
                doctor.name.localizedCaseInsensitiveContains(searchText) ||
                doctor.specialty.localizedCaseInsensitiveContains(searchText) ||
                (doctor.phoneNumber?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (doctor.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
}

// MARK: - Doctor List Content
struct DoctorListContent: View {
    let doctors: [DoctorModel]
    @Binding var searchText: String
    let onDoctorTap: (DoctorModel) -> Void
    let onEditDoctor: (DoctorModel) -> Void
    let onContactDoctor: (DoctorModel) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if doctors.isEmpty && !searchText.isEmpty {
                SearchEmptyState(searchTerm: searchText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Statistics Header
                DoctorStatisticsHeader(doctors: doctors)
                
                // Doctor List
                List {
                    ForEach(groupedDoctors.keys.sorted(), id: \.self) { specialty in
                        if let doctorsInSpecialty = groupedDoctors[specialty] {
                            Section(specialty) {
                                ForEach(doctorsInSpecialty, id: \.id) { doctor in
                                    DoctorRow(
                                        doctor: doctor,
                                        onTap: { onDoctorTap(doctor) },
                                        onEdit: { onEditDoctor(doctor) },
                                        onContact: { onContactDoctor(doctor) }
                                    )
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private var groupedDoctors: [String: [DoctorModel]] {
        Dictionary(grouping: doctors) { $0.specialty }
    }
}

// MARK: - Doctor Statistics Header
struct DoctorStatisticsHeader: View {
    let doctors: [DoctorModel]
    
    private var statistics: DoctorStatistics {
        DoctorStatistics(doctors: doctors)
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.large) {
                StatisticItem(
                    title: AppStrings.Doctors.totalDoctors,
                    value: "\(statistics.totalDoctors)",
                    icon: AppIcons.doctors,
                    color: AppTheme.Colors.primary
                )
                
                Divider()
                    .frame(height: 40)
                
                StatisticItem(
                    title: AppStrings.Doctors.specialties,
                    value: "\(statistics.uniqueSpecialties)",
                    icon: AppIcons.specialties,
                    color: AppTheme.Colors.secondary
                )
                
                Divider()
                    .frame(height: 40)
                
                StatisticItem(
                    title: AppStrings.Doctors.withContact,
                    value: "\(statistics.doctorsWithContact)",
                    icon: AppIcons.contact,
                    color: AppTheme.Colors.success
                )
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            
            if !statistics.recentlyAdded.isEmpty {
                RecentDoctorsSection(doctors: statistics.recentlyAdded)
            }
        }
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.small)
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(AppTheme.Typography.body)
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            Text(title)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Doctors Section
struct RecentDoctorsSection: View {
    let doctors: [DoctorModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(AppStrings.Doctors.recentlyAdded)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.primaryText)
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(doctors.prefix(5), id: \.id) { doctor in
                        RecentDoctorCard(doctor: doctor)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
        }
    }
}

struct RecentDoctorCard: View {
    let doctor: DoctorModel
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Doctor Initials
            Text(doctor.initials)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.onPrimary)
                .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.CornerRadius.extraLarge)
            
            VStack(spacing: AppTheme.Spacing.extraSmall) {
                Text(doctor.displayName)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .lineLimit(1)
                
                Text(doctor.specialty)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .lineLimit(1)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - Doctor Row
struct DoctorRow: View {
    let doctor: DoctorModel
    let onTap: () -> Void
    let onEdit: () -> Void
    let onContact: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Doctor Avatar
                Text(doctor.initials)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.onPrimary)
                    .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(22)
                
                // Doctor Info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(doctor.displayName)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        Text(doctor.specialty)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        if doctor.isImportedFromContacts {
                            Image(systemName: AppIcons.contactImported)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.success)
                        }
                    }
                    
                    if let phoneNumber = doctor.formattedPhoneNumber {
                        Text(phoneNumber)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: AppTheme.Spacing.small) {
                    if doctor.hasContactInfo {
                        Button(action: onContact) {
                            Image(systemName: AppIcons.phone)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: onEdit) {
                        Image(systemName: AppIcons.edit)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.secondary)
                    }

                }
            }
            .padding(.vertical, AppTheme.Spacing.small)
        }

        .contextMenu {
            Button(action: onContact) {
                Label(AppStrings.Doctors.contactDoctor, systemImage: AppIcons.phone)
            }
            .disabled(!doctor.hasContactInfo)
            
            Button(action: onEdit) {
                Label(AppStrings.Common.edit, systemImage: AppIcons.edit)
            }
            
            Button(action: {
                AnalyticsManager.shared.trackFeatureUsed("doctor_share")
            }) {
                Label(AppStrings.Common.share, systemImage: AppIcons.share)
            }
        }
    }
}

// MARK: - Contact Import View
struct ContactImportView: View {
    let onImport: (CNContact, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var contacts: [CNContact] = []
    @State private var selectedContact: CNContact?
    @State private var selectedSpecialty: String = ""
    @State private var isLoading: Bool = true
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    LoadingState(message: AppStrings.Doctors.loadingContacts)
                } else if contacts.isEmpty {
                    EmptyStateView(
                        icon: AppIcons.contacts,
                        title: AppStrings.Doctors.noContacts,
                        message: AppStrings.Doctors.noContactsMessage
                    )
                } else {
                    ContactsList(
                        contacts: filteredContacts,
                        selectedContact: $selectedContact,
                        selectedSpecialty: $selectedSpecialty,
                        onImport: { contact, specialty in
                            onImport(contact, specialty)
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle(AppStrings.Doctors.importFromContacts)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(AppStrings.Common.cancel) {
                    dismiss()
                }
            }
            .searchable(text: $searchText, prompt: AppStrings.Doctors.searchContacts)
        }
        .task {
            await loadContacts()
        }
    }
    
    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                "\(contact.givenName) \(contact.familyName)"
                    .localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadContacts() async {
        isLoading = true
        
        do {
            let store = CNContactStore()
            let keysToFetch = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactPhoneNumbersKey,
                CNContactEmailAddressesKey,
                CNContactOrganizationNameKey
            ] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            var fetchedContacts: [CNContact] = []
            
            try store.enumerateContacts(with: request) { contact, _ in
                // Only include contacts with phone numbers or email addresses
                if !contact.phoneNumbers.isEmpty || !contact.emailAddresses.isEmpty {
                    fetchedContacts.append(contact)
                }
            }
            
            await MainActor.run {
                self.contacts = fetchedContacts.sorted {
                    "\($0.givenName) \($0.familyName)" < "\($1.givenName) \($1.familyName)"
                }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.contacts = []
                self.isLoading = false
            }
        }
    }
}

// MARK: - Contacts List
struct ContactsList: View {
    let contacts: [CNContact]
    @Binding var selectedContact: CNContact?
    @Binding var selectedSpecialty: String
    let onImport: (CNContact, String) -> Void
    
    var body: some View {
        List(contacts, id: \.identifier) { contact in
            ContactRow(
                contact: contact,
                onSelect: { contact, specialty in
                    onImport(contact, specialty)
                }
            )
        }
        .listStyle(PlainListStyle())
    }
}

struct ContactRow: View {
    let contact: CNContact
    let onSelect: (CNContact, String) -> Void
    @State private var showingSpecialtyPicker: Bool = false
    
    var body: some View {
        Button(action: { showingSpecialtyPicker = true }) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Contact Initials
                Text(contactInitials)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.onSecondary)
                    .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                    .background(AppTheme.Colors.secondary)
                    .cornerRadius(AppTheme.CornerRadius.extraLarge)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text("\(contact.givenName) \(contact.familyName)")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    if !contact.organizationName.isEmpty {
                        Text(contact.organizationName)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    
                    if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                        Text(phoneNumber)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog(AppStrings.Doctors.selectSpecialty, isPresented: $showingSpecialtyPicker) {
            ForEach(DoctorModel.CommonSpecialty.sortedCases, id: \.self) { specialty in
                Button(specialty.rawValue) {
                    onSelect(contact, specialty.rawValue)
                }
            }
            
            Button(AppStrings.Common.cancel, role: .cancel) {}
        }
    }
    
    private var contactInitials: String {
        let firstInitial = contact.givenName.first?.uppercased() ?? ""
        let lastInitial = contact.familyName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
}

// MARK: - Doctor Statistics
struct DoctorStatistics {
    let doctors: [DoctorModel]
    
    var totalDoctors: Int {
        doctors.count
    }
    
    var uniqueSpecialties: Int {
        Set(doctors.map { $0.specialty }).count
    }
    
    var doctorsWithContact: Int {
        doctors.filter { $0.hasContactInfo }.count
    }
    
    var recentlyAdded: [DoctorModel] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return doctors.filter { $0.createdAt > oneWeekAgo }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var mostCommonSpecialty: String? {
        let specialtyGroups = Dictionary(grouping: doctors) { $0.specialty }
        return specialtyGroups.max { $0.value.count < $1.value.count }?.key
    }
}

#Preview {
    DoctorListView()
}
