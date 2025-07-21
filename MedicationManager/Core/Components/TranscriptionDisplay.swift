//
//  TranscriptionDisplay.swift
//  MedicationManager
//
//  Component for displaying transcription text
//

import SwiftUI

struct TranscriptionDisplay: View {
    let transcription: String
    let isListening: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            if isListening {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(AppTheme.Typography.caption)
                    
                    Text("Listening...")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
            
            if !transcription.isEmpty {
                Text(transcription)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(AppTheme.Spacing.medium)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
}