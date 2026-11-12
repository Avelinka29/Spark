//
//  LoginView.swift
//  Spark
//
//  Created by mac on 14.06.26.
//

import SwiftUI

struct LoginView: View {
    
    @State private var selectedTab = 0
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var userPassword: String = ""
    @State private var showHome = false
    @State private var showBiometricOffer = false
    @State private var authStore = AuthStore()
    
    var body: some View {
        
        NavigationStack{
        ZStack{
            VStack(spacing: 10){
                LinearGradient(
                    colors: [
                        Color("PrimaryBlue"),
                        Color("PrimaryLitePurple"),
                        Color("PrimaryPurple")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                
                .frame(height: 300)
                
                Color(.systemBackground)
            }
            
            .ignoresSafeArea(edges: .top)
            
            Circle()
                .fill(.primaryYellow)
                .blur(radius: 100)
                .frame(width: 220, height: 220)
                .offset(x: 140, y: -350)
            Spacer()
            
            
            VStack(alignment: .leading, spacing: 18){
                
                HStack{
                    
                    ZStack{
                        
                        Rectangle()
                            .fill(.primaryWhite)
                            .opacity(0.2)
                            .cornerRadius(30)
                            .frame(width: 80, height: 80)
                        
                        Image("LogoFirst")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 45)
                    }
                    
                    
                    Text("Spark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primaryWhite)
                    
                }
                
                if selectedTab == 0 {
                    
                    Text("С возвращением!")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.primaryWhite)
                    Text("Войди, чтобы продолжить искать возможности")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.primaryWhite)
                        .opacity(0.8)
                } else {
                    Text("Создай аккаунт")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.primaryWhite)
                    Text("Начни путь с стажировкам, грантам и  хахатонам")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.primaryWhite)
                        .opacity(0.8)
                }
                Spacer()
                
                VStack(spacing: 20){
                    Spacer()
                    HStack{
                        
                        Button{
                            authStore.clearError()
                            selectedTab = 0
                            
                        }label: {
                            Text("Вход")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedTab == 0
                                                 ? Color(.primaryWhite) : Color(.primaryGrey1))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedTab == 0
                                            ? Color(.primaryLitePurple) : Color.clear)
                                .cornerRadius(15)
                            
                            
                        }
                        Button {
                            authStore.clearError()
                            selectedTab = 1
                        }label: {
                            Text("Регистрация")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedTab == 1
                                                 ? Color(.primaryWhite) : Color(.primaryGrey1))
                            
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedTab == 1
                                            ? Color(.primaryLitePurple) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                            
                            
                        }
                    }
                    .padding(6)
                    .background(SparkColor.surface.color)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.25),
                            radius: 4,
                            x: 0,
                            y: 5)
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    
                    VStack{
                        
                        Button {
                            Task {
                                let succeeded = await authStore.authenticateWithGoogle(
                                    isRegistration: selectedTab == 1
                                )
                                if succeeded {
                                    if authStore.canUseBiometrics && !authStore.isBiometricEnabled {
                                        showBiometricOffer = true
                                    } else {
                                        showHome = true
                                    }
                                }
                            }
                        }
                        label: {
                            HStack(spacing: 10){
                                Image("Google")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20, height: 20)
                                Text("Продолжить с Google")
                                    .foregroundColor(.primaryGrey1)
                                    .font(.system(size: 16, weight: .semibold))
                                
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(SparkColor.surface.color)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(.primaryGrey1.opacity(0.3), lineWidth: 1))
                            .shadow(color: .black.opacity(0.25),
                                    radius: 4,
                                    x: 0,
                                    y: 5)
                            
                            
                        }
                        .disabled(authStore.isLoading)
                        .padding(.bottom, 10)
                        
                        HStack{
                            Rectangle()
                                .fill(.primaryGrey1.opacity(0.3))
                                .frame(width: 135, height: 1)
                            
                            Text ("ИЛИ EMAIL")
                                .foregroundColor(.primaryGrey1.opacity(0.5))
                                .font(.system(size: 14, weight: .medium))
                            
                            Rectangle()
                                .fill(.primaryGrey1.opacity(0.3))
                                .frame(width: 135, height: 1)
                            
                        }.padding(.top, 5)
                            .padding(.bottom, 10)
                        
                        if selectedTab == 0 {
                            
                            SparkTextField(icon: "envelope",
                                           iconColor: .grey,
                                           iconSize: 18,
                                           placeholder: "Email",
                                           borderColor: .grey,
                                           backgroundColor: .surface,
                                           isSecure: false,
                                           text: $userEmail).padding(.bottom, 5)
                            
                            SparkTextField(icon: "lock",
                                           iconColor: .grey,
                                           iconSize: 18,
                                           placeholder: "Пароль",
                                           borderColor: .grey,
                                           backgroundColor: .surface,
                                           isSecure: true,
                                           text: $userPassword).padding(.bottom, 5)
                            HStack{
                                Spacer()
                                Button{}
                                label: {
                                    Text("Забыли пароль?")
                                        .foregroundColor(.primaryLitePurple)
                                        .font(.system(size: 16, weight: .semibold))
                                }.padding(.top, 5)
                            }
                            
                            
                            if let errorMessage = authStore.errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }

                            if authStore.isAuthenticated && authStore.isBiometricEnabled {
                                Button {
                                    Task {
                                        showHome = await authStore.unlockWithBiometrics()
                                    }
                                } label: {
                                    Label("Разблокировать через Face ID", systemImage: "faceid")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.primaryLitePurple)
                            }

                            SparkButton(title: "Войти", icon: "arrow.forward", backgroundColor: .litePurple, isInfinity: true) {
                                Task {
                                    let succeeded = await authStore.login(
                                        email: userEmail,
                                        password: userPassword
                                    )
                                    if succeeded {
                                        if authStore.canUseBiometrics && !authStore.isBiometricEnabled {
                                            showBiometricOffer = true
                                        } else {
                                            showHome = true
                                        }
                                    }
                                }
                            }
                            .disabled(authStore.isLoading)
                            
                            
                            HStack{
                                Spacer()
                                
                                Text("Нет аккаунта?")
                                    .foregroundColor(.primaryGrey1)
                                
                                Button {
                                    selectedTab = 1
                                }
                                label: {
                                    Text("Зарегистрироваться")
                                        .foregroundColor(.primaryLitePurple)
                                        .font(.system(size: 16, weight: .semibold))
                                        .shadow(color: .black.opacity(0.25),
                                                radius: 4,
                                                x: 0,
                                                y: 5
                                        )
                                }
                                
                                
                                Spacer()
                            } .padding(.top, 5)
                            
                            HStack{
                                
                                Spacer()
                                
                                Button {
                                    authStore.continueAsGuest()
                                    showHome = true
                                }
                                label: {
                                    Image(systemName: "arrow.forward")
                                        .foregroundColor(.primaryGrey1.opacity(0.8))
                                        .rotationEffect(.degrees(180))
                                        .fontWeight(.medium)
                                    Text("Пропустить и посмотреть приложение")
                                        .foregroundStyle(.primaryGrey1.opacity(0.8))
                                        .font(.system(size: 14))
                                        
                                    
                                }
                                
                                Spacer()
                            }
                            .padding(.top)
                        } else {
                            
                            SparkTextField(icon: "person",
                                           iconColor: .grey,
                                           iconSize: 18,
                                           placeholder: "Имя",
                                           borderColor: .grey,
                                           backgroundColor: .surface,
                                           isSecure: false,
                                           text: $userName).padding(.bottom, 5)
                            
                            SparkTextField(icon: "envelope",
                                           iconColor: .grey,
                                           iconSize: 18,
                                           placeholder: "Email",
                                           borderColor: .grey,
                                           backgroundColor: .surface,
                                           isSecure: false,
                                           text: $userEmail).padding(.bottom, 5)
                            
                            SparkTextField(icon: "lock",
                                           iconColor: .grey,
                                           iconSize: 18,
                                           placeholder: "Пароль",
                                           borderColor: .grey,
                                           backgroundColor: .surface,
                                           isSecure: true,
                                           text: $userPassword).padding(.bottom, 5)
                            if let errorMessage = authStore.errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }

                            SparkButton(title: "Зарегистрироваться", icon: "arrow.forward", backgroundColor: .litePurple, isInfinity: true) {
                                Task {
                                    let succeeded = await authStore.register(
                                        name: userName,
                                        email: userEmail,
                                        password: userPassword
                                    )
                                    if succeeded {
                                        if authStore.canUseBiometrics && !authStore.isBiometricEnabled {
                                            showBiometricOffer = true
                                        } else {
                                            showHome = true
                                        }
                                    }
                                }
                            }
                            .disabled(authStore.isLoading)
                            
                            
                            HStack{
                                Spacer()
                                
                                Text("Уже с нами?")
                                    .foregroundColor(.primaryGrey1)
                                
                                Button {
                                    selectedTab = 0
                                }
                                label: {
                                    Text("Войти")
                                        .foregroundColor(.primaryLitePurple)
                                        .font(.system(size: 16, weight: .semibold))
                                        .shadow(color: .black.opacity(0.25),
                                                radius: 4,
                                                x: 0,
                                                y: 5
                                        )
                                }
                                
                                
                                Spacer()
                            } .padding(.top, 5)
                            
                            HStack{
                                
                                Spacer()
                                
                                Button {
                                    authStore.continueAsGuest()
                                    showHome = true
                                }
                                label: {
                                    Image(systemName: "arrow.forward")
                                        .foregroundColor(.primaryGrey1.opacity(0.8))
                                        .rotationEffect(.degrees(180))
                                        .fontWeight(.medium)
                                    Text("Пропустить и посмотреть приложение")
                                        .foregroundStyle(.primaryGrey1.opacity(0.8))
                                        .font(.system(size: 14))
                                    
                                }
                                
                                Spacer()
                            }
                            .padding(.top)
                        }}.animation(.easeInOut, value: selectedTab)
                    Spacer()
                }
                
                Spacer()
                
            } .padding(.horizontal, 28)
                .frame(maxWidth: .infinity,alignment: .leading)
            
        }
        .fullScreenCover(isPresented: $showHome) {
            MainTabView(
                accessToken: authStore.accessToken,
                isBiometricEnabled: authStore.isBiometricEnabled,
                canUseBiometrics: authStore.canUseBiometrics,
                onBiometricChange: { enabled in
                    await authStore.setBiometricEnabled(enabled)
                }
            ) {
                authStore.logout()
                showHome = false
            }
        }
        .sensoryFeedback(.success, trigger: showHome) { _, isPresented in
            isPresented
        }
        .alert("Включить Face ID?", isPresented: $showBiometricOffer) {
            Button("Не сейчас") {
                showHome = true
            }
            Button("Включить") {
                Task {
                    _ = await authStore.setBiometricEnabled(true)
                    showHome = true
                }
            }
        } message: {
            Text("Используйте Face ID или код-пароль устройства для быстрой разблокировки Spark.")
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: userName) { _, _ in
            authStore.clearError()
        }
        .onChange(of: userEmail) { _, _ in
            authStore.clearError()
        }
        .onChange(of: userPassword) { _, _ in
            authStore.clearError()
        }
        .task {
            authStore.clearError()
            if authStore.isAuthenticated && authStore.isBiometricEnabled {
                showHome = await authStore.unlockWithBiometrics()
            } else {
                showHome = authStore.isAuthenticated
            }
        }
        }
        
        }
        
    }

#Preview {
    LoginView()
}
