//
//  DropdownPicker.swift
//  Spark
//
//  Created by Avelina Maksimchik on 28.06.2026.
//

import SwiftUI

struct SparkPicker: View {
    
    let title: String
    let options: [String]
    
    @Binding var selection: String
    
    @Binding var showPicker: Bool
    
    
    var body: some View {
        
        ZStack(alignment: .top) {
            Button{
                withAnimation(.easeInOut) {
                    showPicker.toggle()
                }
                
            } label: {
                HStack {
                    Text(selection.isEmpty ? title : selection)
                        .foregroundStyle(selection.isEmpty ? .primaryGrey1: .black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showPicker ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: showPicker)
                        .foregroundStyle(.primaryGrey1)
                }
                
                .padding()
                    .frame(height: 35)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.25),
                            radius: 10,
                            y: 4)
                
            }
//            .overlay(alignment: .topLeading) {
//                if showPicker {
//                    ScrollView {
//                        ForEach(options, id: \.self) {option in
//                            Button {
//                                selection = option
//                                showPicker = false
//                            } label: {
//                                HStack {
//                                    Text(option)
//                                    
//                                    Spacer()
//                                    
//                                    if selection == option{
//                                        
//                                        Image(systemName: "checkmark")
//                                            .foregroundColor(.primaryLitePurple)
//                                        
//                                        
//                                    }
//                                }.padding(.horizontal, 16)
//                                    .padding(.vertical, 10)
//                                    .foregroundStyle(.black)
//                            }
//                            
//                            if option != options.last {
//                                Divider()
//                            }
//                        }
//                    }
//                    .frame(maxHeight: 250)
//                    .background(.white)
//                    .clipShape(RoundedRectangle(cornerRadius: 10))
//                    .shadow(color: .black.opacity(0.25),
//                            radius: 10,
//                            y: 4)
//                    .offset(y: 45)
//                    .zIndex(100)
//                }
//            }

//            if showPicker {
//                
//                
//          
//                
//                    
//                    
//                        ScrollView {
//                        ForEach(options, id: \.self) {option in
//                            Button {
//                                selection = option
//                                showPicker = false
//                            } label: {
//                                HStack {
//                                    Text(option)
//                                    
//                                    Spacer()
//                                    
//                                    if selection == option{
//                                        
//                                        Image(systemName: "checkmark")
//                                            .foregroundColor(.primaryLitePurple)
//                                        
//                                        
//                                    }
//                                }.padding(.horizontal, 16)
//                                    .padding(.vertical, 10)
//                                    .foregroundStyle(.black)
//                            }
//                            
//                            if option != options.last {
//                                Divider()
//                            }
//                        }
//                        }
//                        .frame(maxHeight: 250)
//                        .background(.white)
//                        .clipShape(RoundedRectangle(cornerRadius: 10))
//                        .shadow(color: .black.opacity(0.25),
//                                radius: 10,
//                                y: 4)
//                        .offset(y: 60)
//                        .transition(.move(edge: .top)
//                            .combined(with: .opacity))
//                        .zIndex(2)
//                       
//                    
//                
//                
//
//            }
        }.zIndex(showPicker ? 10 : 0)
            .animation(.easeInOut(duration: 0.2), value: showPicker)
      
    }}


#Preview {
    SparkPicker(title: "Выберите категорию",
                options: ["Хахатоны", "Конкурсы", "Спорт", "Другое","Конкурсы", "Спорт", "Другое"],
                selection: .constant(""), showPicker: .constant(false))
}
