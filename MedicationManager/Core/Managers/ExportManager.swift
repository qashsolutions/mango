import SwiftUI
import PDFKit
import UniformTypeIdentifiers

@MainActor
@Observable
final class ExportManager {
    static let shared = ExportManager()
    
    // Export state
    var isExporting = false
    var exportProgress: Double = 0.0
    var lastExportedURL: URL?
    var lastError: Error?
    
    private let coreDataManager = CoreDataManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    private init() {}
    
    // MARK: - Export Methods
    
    func exportMedicationList(format: ExportFormat) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        defer { 
            isExporting = false
            exportProgress = 1.0
        }
        
        guard let userId = firebaseManager.currentUser?.id else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        // Fetch data
        exportProgress = 0.2
        let medications = try await coreDataManager.fetchMedications(for: userId)
        let supplements = try await coreDataManager.fetchSupplements(for: userId)
        let doctors = try await coreDataManager.fetchDoctors(for: userId)
        
        exportProgress = 0.4
        
        // Generate export based on format
        let url: URL
        switch format {
        case .pdf:
            url = try await generatePDF(
                medications: medications,
                supplements: supplements,
                doctors: doctors
            )
        case .csv:
            url = try generateCSV(
                medications: medications,
                supplements: supplements
            )
        case .text:
            url = try generateTextFile(
                medications: medications,
                supplements: supplements,
                doctors: doctors
            )
        }
        
        exportProgress = 1.0
        lastExportedURL = url
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(
            "medication_list_exported",
            parameters: [
                "format": format.rawValue,
                "medication_count": medications.count,
                "supplement_count": supplements.count
            ]
        )
        
        return url
    }
    
    // MARK: - PDF Generation
    
    private func generatePDF(
        medications: [MedicationModel],
        supplements: [SupplementModel],
        doctors: [DoctorModel]
    ) async throws -> URL {
        let pdfMetaData = [
            kCGPDFContextCreator: AppStrings.App.name,
            kCGPDFContextTitle: NSLocalizedString("export.pdf.title", value: "Medication List", comment: "PDF title"),
            kCGPDFContextSubject: NSLocalizedString("export.pdf.subject", value: "Personal Medication and Supplement List", comment: "PDF subject")
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            // Header
            drawPDFHeader(in: context, at: &yPosition)
            
            // User info
            drawUserInfo(in: context, at: &yPosition)
            
            // Medications section
            if !medications.isEmpty {
                drawSectionHeader("Medications", in: context, at: &yPosition)
                for medication in medications {
                    if yPosition > 700 {
                        context.beginPage()
                        yPosition = 50
                    }
                    drawMedication(medication, in: context, at: &yPosition)
                }
            }
            
            // Supplements section
            if !supplements.isEmpty {
                yPosition += 20
                if yPosition > 650 {
                    context.beginPage()
                    yPosition = 50
                }
                drawSectionHeader("Supplements", in: context, at: &yPosition)
                for supplement in supplements {
                    if yPosition > 700 {
                        context.beginPage()
                        yPosition = 50
                    }
                    drawSupplement(supplement, in: context, at: &yPosition)
                }
            }
            
            // Doctors section
            if !doctors.isEmpty {
                yPosition += 20
                if yPosition > 650 {
                    context.beginPage()
                    yPosition = 50
                }
                drawSectionHeader("Healthcare Providers", in: context, at: &yPosition)
                for doctor in doctors {
                    if yPosition > 700 {
                        context.beginPage()
                        yPosition = 50
                    }
                    drawDoctor(doctor, in: context, at: &yPosition)
                }
            }
            
            // Footer
            drawPDFFooter(in: context)
        }
        
        // Save to documents directory
        let fileName = "MedicationList_\(Date().ISO8601Format()).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        
        return url
    }
    
    private func drawPDFHeader(in context: UIGraphicsPDFRendererContext, at yPosition: inout CGFloat) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        
        let title = NSLocalizedString("export.pdf.header", value: "Personal Medication List", comment: "PDF header")
        title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
        
        yPosition += 40
        
        // Date
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let dateString = "Generated on: \(Date().formatted(date: .long, time: .shortened))"
        dateString.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: dateAttributes)
        
        yPosition += 30
    }
    
    private func drawUserInfo(in context: UIGraphicsPDFRendererContext, at yPosition: inout CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label
        ]
        
        if let userName = firebaseManager.currentUser?.displayName {
            "Name: \(userName)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
            yPosition += 20
        }
        
        yPosition += 10
    }
    
    private func drawSectionHeader(_ title: String, in context: UIGraphicsPDFRendererContext, at yPosition: inout CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        
        title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
        yPosition += 30
        
        // Draw line
        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
        context.cgContext.setLineWidth(1)
        context.cgContext.move(to: CGPoint(x: 50, y: yPosition))
        context.cgContext.addLine(to: CGPoint(x: 562, y: yPosition))
        context.cgContext.strokePath()
        
        yPosition += 10
    }
    
    private func drawMedication(_ medication: MedicationModel, in context: UIGraphicsPDFRendererContext, at yPosition: inout CGFloat) {
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.label
        ]
        
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        // Name and dosage
        let nameText = "\(medication.name) - \(medication.dosage)"
        nameText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: nameAttributes)
        yPosition += 20
        
        // Frequency
        let frequencyText = "Frequency: \(medication.frequency.displayName)"
        frequencyText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
        yPosition += 18
        
        // Prescribed by
        if let prescribedBy = medication.prescribedBy {
            let prescriberText = "Prescribed by: \(prescribedBy)"
            prescriberText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
            yPosition += 18
        }
        
        // Active status
        let statusText = "Status: \(medication.isActive ? "Active" : "Inactive")"
        statusText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
        yPosition += 25
    }
    
    private func drawSupplement(_ supplement: SupplementModel, in context: UIGraphicsPDFRendererContext, at yPosition: inout CGFloat) {
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.label
        ]
        
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        // Name and dosage
        let nameText = "\(supplement.name) - \(supplement.dosage)"
        nameText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: nameAttributes)
        yPosition += 20
        
        // Purpose
        if let purpose = supplement.purpose {
            let purposeText = "Purpose: \(purpose)"
            purposeText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
            yPosition += 18
        }
        
        // Take with food
        if supplement.isTakenWithFood {
            let foodText = "Take with food"
            foodText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
            yPosition += 18
        }
        
        yPosition += 7
    }
    
    private func drawDoctor(_ doctor: DoctorModel, in context: UIGraphicsPDFRendererContext, at yPosition: inout CGFloat) {
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.label
        ]
        
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        // Name
        doctor.name.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: nameAttributes)
        yPosition += 20
        
        // Specialty
        doctor.specialty.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
        yPosition += 18
        
        // Contact info
        if let phone = doctor.phoneNumber {
            "Phone: \(phone)".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
            yPosition += 18
        }
        
        if let email = doctor.email {
            "Email: \(email)".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
            yPosition += 18
        }
        
        yPosition += 7
    }
    
    private func drawPDFFooter(in context: UIGraphicsPDFRendererContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        
        let disclaimer = AppStrings.Legal.medicalDisclaimer
        let exportDate = "Exported: \(Date().formatted(date: .abbreviated, time: .shortened))"
        
        disclaimer.draw(at: CGPoint(x: 50, y: 750), withAttributes: attributes)
        exportDate.draw(at: CGPoint(x: 480, y: 750), withAttributes: attributes)
    }
    
    // MARK: - CSV Generation
    
    private func generateCSV(
        medications: [MedicationModel],
        supplements: [SupplementModel]
    ) throws -> URL {
        var csvString = "Type,Name,Dosage,Frequency,Status,Start Date,End Date,Notes\n"
        
        // Add medications
        for medication in medications {
            let row = [
                "Medication",
                medication.name,
                medication.dosage,
                medication.frequency.displayName,
                medication.isActive ? "Active" : "Inactive",
                medication.startDate.ISO8601Format(),
                medication.endDate?.ISO8601Format() ?? "",
                medication.notes ?? ""
            ]
            csvString += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
        }
        
        // Add supplements
        for supplement in supplements {
            let row = [
                "Supplement",
                supplement.name,
                supplement.dosage,
                supplement.frequency.displayName,
                supplement.isActive ? "Active" : "Inactive",
                supplement.startDate.ISO8601Format(),
                supplement.endDate?.ISO8601Format() ?? "",
                supplement.notes ?? ""
            ]
            csvString += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
        }
        
        // Save to file
        let fileName = "MedicationList_\(Date().ISO8601Format()).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvString.write(to: url, atomically: true, encoding: .utf8)
        
        return url
    }
    
    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    // MARK: - Text File Generation
    
    private func generateTextFile(
        medications: [MedicationModel],
        supplements: [SupplementModel],
        doctors: [DoctorModel]
    ) throws -> URL {
        var content = "PERSONAL MEDICATION LIST\n"
        content += "Generated: \(Date().formatted(date: .long, time: .shortened))\n"
        content += String(repeating: "=", count: 50) + "\n\n"
        
        // Medications
        if !medications.isEmpty {
            content += "MEDICATIONS\n"
            content += String(repeating: "-", count: 30) + "\n"
            for medication in medications {
                content += "\n\(medication.name)\n"
                content += "  Dosage: \(medication.dosage)\n"
                content += "  Frequency: \(medication.frequency.displayName)\n"
                content += "  Status: \(medication.isActive ? "Active" : "Inactive")\n"
                if let prescribedBy = medication.prescribedBy {
                    content += "  Prescribed by: \(prescribedBy)\n"
                }
                if let notes = medication.notes {
                    content += "  Notes: \(notes)\n"
                }
            }
            content += "\n"
        }
        
        // Supplements
        if !supplements.isEmpty {
            content += "SUPPLEMENTS\n"
            content += String(repeating: "-", count: 30) + "\n"
            for supplement in supplements {
                content += "\n\(supplement.name)\n"
                content += "  Dosage: \(supplement.dosage)\n"
                content += "  Frequency: \(supplement.frequency.displayName)\n"
                if let purpose = supplement.purpose {
                    content += "  Purpose: \(purpose)\n"
                }
                if supplement.isTakenWithFood {
                    content += "  Take with food\n"
                }
            }
            content += "\n"
        }
        
        // Doctors
        if !doctors.isEmpty {
            content += "HEALTHCARE PROVIDERS\n"
            content += String(repeating: "-", count: 30) + "\n"
            for doctor in doctors {
                content += "\n\(doctor.name)\n"
                content += "  Specialty: \(doctor.specialty)\n"
                if let phone = doctor.phoneNumber {
                    content += "  Phone: \(phone)\n"
                }
                if let email = doctor.email {
                    content += "  Email: \(email)\n"
                }
            }
            content += "\n"
        }
        
        content += "\n" + AppStrings.Legal.medicalDisclaimer
        
        // Save to file
        let fileName = "MedicationList_\(Date().ISO8601Format()).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try content.write(to: url, atomically: true, encoding: .utf8)
        
        return url
    }
    
    // MARK: - Share Functionality
    
    func shareExport(url: URL, from viewController: UIViewController) {
        let activityController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityController, animated: true)
    }
}

// MARK: - Export Format
enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case csv = "CSV"
    case text = "Text"
    
    var displayName: String {
        switch self {
        case .pdf:
            return NSLocalizedString("export.format.pdf", value: "PDF Document", comment: "PDF format")
        case .csv:
            return NSLocalizedString("export.format.csv", value: "CSV Spreadsheet", comment: "CSV format")
        case .text:
            return NSLocalizedString("export.format.text", value: "Text File", comment: "Text format")
        }
    }
    
    var icon: String {
        switch self {
        case .pdf:
            return "doc.fill"
        case .csv:
            return "tablecells.fill"
        case .text:
            return "doc.text.fill"
        }
    }
    
    var utType: UTType {
        switch self {
        case .pdf:
            return .pdf
        case .csv:
            return .commaSeparatedText
        case .text:
            return .plainText
        }
    }
}