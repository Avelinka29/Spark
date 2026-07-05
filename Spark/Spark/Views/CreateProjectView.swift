//
//  CreateProjectView.swift
//  Spark
//
//  Created by YULIYA MAKSIMCHYK on 24.06.2026.
//

import SwiftUI

struct CreateProjectView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectTitle = ""
    @State private var projectDescription = ""
    
    @State private var ownerRole = ""
    
    @State private var selectedCategory = ""
    
    @State private var selectedRole: Set<String> = []
    
    @State private var createProject: Bool = false
    
    @State private var showCategoryPicker = false
    
    struct ProjectRole: Identifiable {
        let id = UUID()
        var name: String = ""
        var skils: String = ""
    }
    
    @State private var projectRoles: [ProjectRole] = [ProjectRole()]

    
    let category = [
        "FinTech",
        "EdTech",
        "GreenTech",
        "HealthTech",
        "Социальный проект",
        "Другое"
    ]
    
    let roles = [
        "Backend Developer",
        "Fronted Developer",
        "iOS Developer",
        "Android Developer",
        "UI/UX Designer",
        "ML",
        "QA",
        "Project Manager"
        
    ]
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                VStack(spacing: 0){
                    
                    
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color("PrimaryBlue"),
                                Color("PrimaryLitePurple"),
                                Color("PrimaryPurple")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                        
                        Circle()
                            .fill(.primaryYellow)
                            .blur(radius: 60)
                            .frame(width: 100, height: 120)
                            .offset(x: 160, y: 8)
                        
                        HStack {
                            Text("Новый проект")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primaryWhite)
                            
                            Spacer()
                            
                            ZStack{
                                
                                Rectangle()
                                    .fill(.primaryWhite)
                                    .opacity(0.4)
                                    .cornerRadius(30)
                                    .frame(width: 40, height: 40)
                                
                                Image("LogoFirst")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22)
                            }
                            
                        }.padding(.top, 50)
                            .padding(.horizontal, 20)
                        
                    }.zIndex(1)
                    .frame(height: 120)
                        .ignoresSafeArea(edges: .top)
                    
                    
                    
                    ScrollView{
                        
                        VStack {
                    
                    
                            
                            Spacer()
                            
                            VStack{
                                HStack{
                                    Text("Название проекта")
                                        .foregroundStyle(Color(.primaryGreyDark2))
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                }
                                SparkTextField( placeholder: "Например: StoneGate", text: $projectDescription, height: 35, cornerRadius: 10)
                            }
                            
                            Spacer()
                            
                            VStack{
                                HStack{
                                    Text("Описание")
                                        .foregroundStyle(Color(.primaryGreyDark2))
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                }
                                //TODO: заменить на большой текст файлд для описания
                                SparkTextField( placeholder: "Расскажи, что делает проект и для кого", text: $projectTitle, height: 35, cornerRadius: 10)
                            }
                            
                            Spacer()
                            
                            
                            
                            VStack {
                                HStack{
                                    Text("Категория")
                                        .foregroundStyle(Color(.primaryGreyDark2))
                                        .font(.system(size: 16, weight: .semibold))
                                        .padding(.top, 20)
                                    Spacer()
                                    
                                    
                                }
                                SparkPicker(title: "Выберите категорию",
                                            options: category,
                                            selection: $selectedCategory, showPicker: $showCategoryPicker )
                                
                            }
                            
                            Spacer()
                            
                            VStack{
                                HStack {
                                    
                                    Text("Роли в команде")
                                        .foregroundStyle(Color(.primaryGreyDark2))
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Spacer()
                                    
                                    HStack{
                                        
                                        
                                        Button {
                                            projectRoles.append(ProjectRole())
                                        }
                                        label: {
                                            Image(systemName: "plus")
                                                .foregroundStyle(Color(.primaryLitePurple))
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Добавить роль")
                                                .foregroundStyle(Color(.primaryLitePurple))
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        
                                    }
                                }.padding(.top, 20)
                            }
                            
                            
                            ForEach(projectRoles.indices, id: \.self) {index in
                                
                                VStack(alignment: .leading, spacing: 20){
                                    
                                    
                                    HStack{
                                        
                                    
                                    Text("Название роли")
                                        .foregroundStyle(Color(.primaryGreyDark2))
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Spacer ()
                                        
                                        Button(role: .destructive){
                                            projectRoles.remove(at: index)}
                                        label: {
                                                Image(systemName: "trash")
                                                
                                            }
                                    }
                                    
                                    
                                    SparkTextField(placeholder: "iOS Developer", text: $projectRoles[index].name, height: 35, cornerRadius: 10)
                                    
                                    Divider()
                                    
                                    Text("Навыки")
                                        .foregroundStyle(Color(.primaryGreyDark2))
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    SparkTextField(placeholder: "Swift/SwiftUI", text: $projectRoles[index].skils, height: 35, cornerRadius: 10)
                                    
                                    
                                }
                            
                                
                            }.frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.primaryGrey3.opacity(0.1)))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.primaryGrey3.opacity(0.3), lineWidth: 1))
                            

                                
                                
                            }
                            
                        }.padding(.horizontal, 20)
                            .padding(.vertical, 20)
                        
                        
                    }.scrollClipDisabled(true)
                        .safeAreaBar(edge: .bottom){
                            SparkButton(title: "Создать проект", icon: nil, backgroundColor: .litePurple, isInfinity: true){
                                createProject = true
                                dismiss()
                                
                        }.padding(.horizontal, 20)
                                .padding(.vertical, 20)
                        
                    

                    
                }
                
            if showCategoryPicker {
                
                ZStack{
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .onTapGesture {withAnimation
                            {showCategoryPicker = false}}
                    
                    VStack {
                        categoryDropdown
                            .padding(.top, 380)
                        Spacer()
                    }
                    
                    
                    
                }
            }
                
            }
        }}
    
    private var categoryDropdown: some View {
        


            VStack(spacing: 0) {
                ForEach(category, id: \.self) { option in
                    Button {
                        selectedCategory = option

                        withAnimation {
                            showCategoryPicker = false
                        }
                    } label: {
                        HStack {
                            Text(option)

                            Spacer()

                            if selectedCategory == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.primaryLitePurple)
                            }
                        }
                        .padding()
                        .foregroundStyle(.black)
                    }

                    if option != category.last {
                        Divider()
                    }
                }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.horizontal, 20)

 
        }
    
    }


#Preview {
    CreateProjectView()
}
