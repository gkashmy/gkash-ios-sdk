//
//  ContentView.swift
//  GkashPaymentIOS
//
//  Created by Gkash on 07/09/2022.
//

import SwiftUI
import GkashPayment

struct ContentView: View, TransStatusCallback {
    func getStatus(response: PaymentResponse) {
        print("getStatus: " + response.status)
        paymentResponse = response
        currentPage = "ResponsePage"
        isShowingView = false
    }

    private enum PaymentOption {
        case submit, bind, recurring
    }

    private enum Field {
        case amount, epKey
    }

    // Merchant credentials and environment, edited on the Settings page
    @AppStorage("merchant_id") private var merchantId: String = ""
    @AppStorage("signature_key") private var signatureKey: String = ""
    @AppStorage("production") private var production: Bool = false

    @State private var amount: String = "0.10"
    @State private var epKey: String = ""
    @State private var request : PaymentRequest = PaymentRequest()
    @State private var paymentResponse: PaymentResponse = PaymentResponse()
    @State private var currentPage = "MainPage"
    @State private var isShowingView = false
    @State private var isShowingSettings = false
    @State private var toastMessage: String?
    @FocusState private var focusedField: Field?

    private var isAmountValid: Bool {
        (Double(amount) ?? 0) > 0
    }

    private var isEpKeyEmpty: Bool {
        epKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // False until the user saves credentials on the Settings page
    private var hasCredentials: Bool {
        !merchantId.isEmpty && !signatureKey.isEmpty
    }

    func generateRequest() -> PaymentRequest {
        //cid and signaturekey come from the Settings page
        //cartId must be unique
        //returnUrl will be your APP URL Scheme. eg: gkash
        //isProd follows the Production toggle on the Settings page, false = staging environment
        let request = PaymentRequest(
            cid: merchantId,
            signatureKey: signatureKey,
            amount: amount,
            cartId: "IOSSDK" + String(format: "%.0f",  NSDate().timeIntervalSince1970),
            isProd: production,
            returnUrl: "gkash://returntoapp",
            callback: self,
            callbackUrl: "https://paymentdemo.gkash.my/callback.php"
        )
        request.email = "test@example.com"
        request.mobileNo = "0123456789"
        return request
    }

    private func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }

    private func startPayment(_ option: PaymentOption) {
        focusedField = nil
        // Send the user to Settings when no credentials are saved yet
        guard hasCredentials else {
            showToast("Enter your Merchant ID and Signature Key first")
            isShowingSettings = true
            return
        }
        let request = generateRequest()
        switch option {
        case .submit:
            break
        case .bind:
            request.recurringType = "MONTHLY"
        case .recurring:
            request.recurringType = "MONTHLY"
            request.epKey = epKey.trimmingCharacters(in: .whitespaces)
            request.hostToHost = true
        }
        self.request = request
        isShowingView = true
    }

    var body: some View {
        Group {
            switch currentPage {
            case "MainPage":
                checkoutPage
            case "ResponsePage":
                resultPage
            default:
                Text("default")
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = toastMessage {
                Toast(message: toastMessage)
                    .padding(.bottom, 32)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toastMessage)
        .preferredColorScheme(.light)
    }

    private var checkoutPage: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Checkout Demo")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Palette.textPrimary)
                        // Merchant ID and environment from Settings
                        Text((merchantId.isEmpty ? "Merchant ID not set" : merchantId) + " · " + (production ? "Production" : "Staging"))
                            .font(.system(size: 14))
                            .foregroundColor(Palette.textSecondary)
                    }
                    .padding(.top, 8)

                    // Amount card, shared by every payment option below
                    Card {
                        CardHeader(title: "Amount", subtitle: "Used for Submit, Bind and Recurring.")
                        HStack(spacing: 10) {
                            Text("MYR")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Palette.textSecondary)
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .amount)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Palette.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 60)
                        .background(InputBackground(isFocused: focusedField == .amount))
                        .padding(.top, 16)
                    }

                    // Payment card
                    Card {
                        CardHeader(title: "Payment", subtitle: "Pay once, or bind a card for future charges.")
                        Button("Submit") { startPayment(.submit) }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.top, 20)
                        Button("Bind") { startPayment(.bind) }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.top, 12)
                    }
                    .disabled(!isAmountValid)

                    // Recurring card
                    Card {
                        CardHeader(title: "Recurring", subtitle: "Charge a bound card host-to-host with its Ep Key.")
                        FieldLabel(text: "EP KEY")
                        TextField("Enter Ep Key", text: $epKey)
                            .focused($focusedField, equals: .epKey)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .font(.system(size: 16))
                            .foregroundColor(Palette.textPrimary)
                            .padding(.horizontal, 14)
                            .frame(height: 52)
                            .background(InputBackground(isFocused: focusedField == .epKey))
                        Button("Recurring") { startPayment(.recurring) }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.top, 20)
                            .disabled(!isAmountValid || isEpKeyEmpty)
                    }
                }
                .padding(16)
            }
            .background(Palette.screenBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        focusedField = nil
                        isShowingSettings = true
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .background(
                NavigationLink(destination: paymentPage, isActive: $isShowingView) { EmptyView() }
                    .hidden()
            )
            .background(
                NavigationLink(destination: settingsPage, isActive: $isShowingSettings) { EmptyView() }
                    .hidden()
            )
        }
        .navigationViewStyle(.stack)
    }

    private var settingsPage: some View {
        SettingsView(merchantId: merchantId, signatureKey: signatureKey, production: production) { merchantId, signatureKey, production in
            self.merchantId = merchantId
            self.signatureKey = signatureKey
            self.production = production
            showToast("Settings saved")
            isShowingSettings = false
        }
    }

    private var paymentPage: some View {
        GkashPaymentSDK(request: request)
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
    }

    private var resultPage: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary card
                Card(alignment: .center, verticalPadding: 28) {
                    Text("Payment Result")
                        .font(.system(size: 14))
                        .foregroundColor(Palette.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(paymentResponse.currency)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Palette.textSecondary)
                        Text(paymentResponse.amount)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Palette.textPrimary)
                    }
                    .padding(.top, 8)
                    StatusPill(status: paymentResponse.status)
                        .padding(.top, 14)
                    Text(paymentResponse.description)
                        .font(.system(size: 14))
                        .foregroundColor(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                }

                // Details card
                Card(verticalPadding: 8) {
                    DetailRow(label: "Cart ID", value: paymentResponse.cartid)
                    CardDivider()
                    DetailRow(label: "Payment Type", value: paymentResponse.PaymentType)
                    // Shown only when the response has an epkey (bind / recurring)
                    if !paymentResponse.epkey.isEmpty {
                        CardDivider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ep Key")
                                .font(.system(size: 14))
                                .foregroundColor(Palette.textSecondary)
                            Text(paymentResponse.epkey)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Palette.textPrimary)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 14)
                    }
                }

                Button("Back to Checkout") { currentPage = "MainPage" }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Palette.screenBackground.ignoresSafeArea())
    }
}

private struct SettingsView: View {
    private enum Field {
        case merchantId, signatureKey
    }

    let onSave: (String, String, Bool) -> Void
    @State private var merchantId: String
    @State private var signatureKey: String
    @State private var production: Bool
    @State private var keyVisible = false
    @State private var merchantIdError: String?
    @State private var signatureKeyError: String?
    @FocusState private var focusedField: Field?

    // Start from the saved values, edits stay local until Save
    init(merchantId: String, signatureKey: String, production: Bool, onSave: @escaping (String, String, Bool) -> Void) {
        self.onSave = onSave
        _merchantId = State(initialValue: merchantId)
        _signatureKey = State(initialValue: signatureKey)
        _production = State(initialValue: production)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Credentials card
                Card {
                    CardHeader(title: "Credentials", subtitle: "Issued by Gkash for your merchant account.")
                    FieldLabel(text: "MERCHANT ID")
                    TextField("M102-U-xxx", text: $merchantId)
                        .focused($focusedField, equals: .merchantId)
                        // Not a login form, keeps iOS from offering to save these as a password
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .font(.system(size: 16))
                        .foregroundColor(Palette.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(InputBackground(isFocused: focusedField == .merchantId, isError: merchantIdError != nil))
                    FieldError(message: merchantIdError)
                    FieldLabel(text: "SIGNATURE KEY")
                    HStack(spacing: 10) {
                        Group {
                            if keyVisible {
                                TextField("Enter Signature Key", text: $signatureKey)
                            } else {
                                SecureField("Enter Signature Key", text: $signatureKey)
                            }
                        }
                        .focused($focusedField, equals: .signatureKey)
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .font(.system(size: 16))
                        .foregroundColor(Palette.textPrimary)
                        Button(keyVisible ? "Hide" : "Show") {
                            let wasFocused = focusedField == .signatureKey
                            keyVisible.toggle()
                            // Swapping between SecureField and TextField drops focus, so put it back
                            if wasFocused {
                                DispatchQueue.main.async { focusedField = .signatureKey }
                            }
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Palette.primary)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(InputBackground(isFocused: focusedField == .signatureKey, isError: signatureKeyError != nil))
                    FieldError(message: signatureKeyError)
                }

                // Environment card
                Card {
                    HStack(spacing: 12) {
                        CardHeader(title: "Production",
                                   subtitle: production
                                   ? "On: payments go to production (api.gkash.my)."
                                   : "Off: payments go to staging (api-staging.pay.asia).")
                        Spacer(minLength: 0)
                        Toggle("Production", isOn: $production)
                            .labelsHidden()
                            .tint(Palette.primary)
                    }
                }

                Button("Save") { save() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Palette.screenBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: merchantId) { _ in merchantIdError = nil }
        .onChange(of: signatureKey) { _ in signatureKeyError = nil }
    }

    private func save() {
        let merchantId = merchantId.trimmingCharacters(in: .whitespacesAndNewlines)
        let signatureKey = signatureKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if merchantId.isEmpty {
            merchantIdError = "Merchant ID is required"
            focusedField = .merchantId
            return
        }
        if signatureKey.isEmpty {
            signatureKeyError = "Signature key is required"
            focusedField = .signatureKey
            return
        }
        focusedField = nil
        onSave(merchantId, signatureKey, production)
    }
}

private enum Palette {
    static let primary = Color(hex: 0x1E5EFF)
    static let primaryPressed = Color(hex: 0x1646C4)
    static let primaryTint = Color(hex: 0xEAF0FF)
    static let screenBackground = Color(hex: 0xF3F5F9)
    static let cardBackground = Color(hex: 0xFFFFFF)
    static let cardStroke = Color(hex: 0xE3E7EF)
    static let inputStroke = Color(hex: 0xCCD3DF)
    static let textPrimary = Color(hex: 0x1A1F2B)
    static let textSecondary = Color(hex: 0x6B7385)
    static let statusSuccess = Color(hex: 0x1B8A4B)
    static let statusSuccessBg = Color(hex: 0xE4F5EA)
    static let statusPending = Color(hex: 0xB26A00)
    static let statusPendingBg = Color(hex: 0xFFF3DD)
    static let statusFailed = Color(hex: 0xC62828)
    static let statusFailedBg = Color(hex: 0xFDE7E7)
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

private struct Card<Content: View>: View {
    var alignment: HorizontalAlignment = .leading
    var verticalPadding: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        .padding(.horizontal, 20)
        .padding(.vertical, verticalPadding)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.cardStroke, lineWidth: 1))
    }
}

private struct CardHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Palette.textPrimary)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(Palette.textSecondary)
        }
    }
}

private struct CardDivider: View {
    var body: some View {
        Rectangle()
            .fill(Palette.cardStroke)
            .frame(height: 1)
    }
}

private struct InputBackground: View {
    let isFocused: Bool
    var isError: Bool = false

    private var strokeColor: Color {
        isError ? Palette.statusFailed : isFocused ? Palette.primary : Palette.inputStroke
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Palette.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(strokeColor, lineWidth: isFocused || isError ? 2 : 1)
            )
    }
}

private struct FieldLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Palette.textSecondary)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }
}

private struct FieldError: View {
    let message: String?

    var body: some View {
        if let message = message {
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Palette.statusFailed)
                .padding(.top, 6)
        }
    }
}

private struct Toast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.black.opacity(0.8)))
            .padding(.horizontal, 24)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Palette.textSecondary)
            Spacer(minLength: 16)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Palette.textPrimary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .padding(.vertical, 14)
    }
}

// Colour the status pill: 88 = success, 11 = pending, anything else = failed
private struct StatusPill: View {
    let status: String

    private var colors: (text: Color, background: Color) {
        if status.hasPrefix("88") {
            return (Palette.statusSuccess, Palette.statusSuccessBg)
        } else if status.hasPrefix("11") {
            return (Palette.statusPending, Palette.statusPendingBg)
        }
        return (Palette.statusFailed, Palette.statusFailedBg)
    }

    var body: some View {
        Text(status)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(colors.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Capsule().fill(colors.background))
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(!isEnabled ? Palette.inputStroke : configuration.isPressed ? Palette.primaryPressed : Palette.primary)
            )
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let tint = isEnabled ? Palette.primary : Palette.inputStroke
        return configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(configuration.isPressed ? Palette.primaryTint : Palette.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(tint, lineWidth: 1.5)
            )
    }
}
