//
//  MockupView.swift
//  M
//
//  Created by Sean Kelly on 29/11/2023.
//

import SwiftUI
import TipKit

struct MockupView: View {
    
    @StateObject var viewModel: ContentViewModel
    @StateObject var obj: Object
    @AppStorage("saveCount") private var saveCount: Int = 0
    
    var colorScheme: ColorScheme? {
        switch obj.appearance.selectedAppearance {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    @Binding var showPremiumContent: Bool
    @Binding var buyClicked: Bool
    
    var body: some View {
        ZStack {
          
            // MARK: Wallpaper View
            CustomPagingSlider(data: $viewModel.items) { $item in
                
                CustomImageView(item: item, importedBackground: $viewModel.importedBackground, importedImage1: $viewModel.importedImage1, importedImage2: $viewModel.importedImage2, importedLogo: $viewModel.importedLogo, obj: obj)
                    .customImageViewModifier(obj: obj, viewModel: viewModel)
                
                ShareImageButton(showSymbolEffect: $obj.appearance.showSymbolEffect, importedBackground: $viewModel.importedBackground, importedImage1: $viewModel.importedImage1, importedImage2: $viewModel.importedImage2, importedLogo: $viewModel.importedLogo, item: item, obj: obj, saveCount: $saveCount)
                    .titleViewModifier(obj: obj, normalScale: 1.0)
                
            } titleContent: { $item in
                
                VStack(spacing: 5) {
                    
                    Text(item.title)
                        .font(.largeTitle.bold())
                    
                    Text(item.subTitle)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .frame(height: 45)
                }
                .titleViewModifier(obj: obj, normalScale: 0.8)
            }
            .safeAreaPadding([.horizontal, .top], 35)
            .fullScreenCover(isPresented: $viewModel.showImagePickerSheet1) {
                fullScreenImagePickerCover(for: $viewModel.importedImage1) { images in
                    viewModel.importedImage1 = images.first
                }
            }
            .fullScreenCover(isPresented: $viewModel.showImagePickerSheet2) {
                fullScreenImagePickerCover(for: $viewModel.importedImage2) { images in
                    viewModel.importedImage2 = images.first
                }
            }
            .fullScreenCover(isPresented: $viewModel.showBgPickerSheet) {
                fullScreenImagePickerCover(for: $viewModel.importedBackground) { images in
                    viewModel.importedBackground = images.first
                }
            }
            .fullScreenCover(isPresented: $viewModel.showLogoPickerSheet) {
                fullScreenImagePickerCover(for: $viewModel.importedLogo) { images in
                    viewModel.importedLogo = images.first
                }
            }
            .sheet(isPresented: $obj.appearance.showSettingsSheet, content: {
                SettingsView(viewModel: viewModel, obj: obj)
            })
            .sheet(isPresented: $obj.appearance.showApplicationSettings, content: {
                ApplicationSettings(obj: obj, showPremiumContent: $showPremiumContent, buyClicked: $buyClicked)
            })
            
            //MARK: Pill Buttons for importing images etc
            importButtons(obj: obj, saveCount: $saveCount, viewModel: viewModel)
            
        }
        .onAppear {
            let _ = IAP.shared
        }
        //MARK: Add system to mode toggle
        .preferredColorScheme(colorScheme)
        .onTapGesture {
            withAnimation(.bouncy){
                if !obj.appearance.showPill {
                    obj.appearance.showPill = true
                }
            }
        }
        .gesture( // MARK: Drag up gesture to show settings sheet
            DragGesture(minimumDistance: 30, coordinateSpace: .global)
                .onEnded { value in
                    if value.translation.height < 0 {
                        obj.appearance.showSettingsSheet.toggle()
                        withAnimation(.bouncy){
                            if !obj.appearance.showPill {
                                obj.appearance.showPill = true
                            }
                        }
                    }
                })
        // MARK: Show Tips
        .task {
            //   try? Tips.resetDatastore() //MARK:  Disable this once tested - shows tips all the time
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)])
        }
    }
    
    private func fullScreenImagePickerCover(for binding: Binding<UIImage?>, completion: @escaping ([UIImage]) -> Void) -> some View {
        PhotoPicker(filter: .images, limit: 1) { results in
            PhotoPicker.convertToUIImageArray(fromResults: results) { (imagesOrNil, errorOrNil) in
                if let error = errorOrNil {
                    print(error)
                }
                if let images = imagesOrNil {
                    completion(images)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

extension View {
    func customImageViewModifier(obj: Object, viewModel: ContentViewModel) -> some View {
        self
            .scaleEffect(0.5)
            .frame(width: obj.appearance.frameWidth * 0.5, height: obj.appearance.frameHeight * 0.5)
            .clipped()
            .cornerRadius(15)
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray, lineWidth: 0.5)
            }
            .addPinchZoom()
            .scaleEffect(obj.appearance.screenWidth, anchor: .center)
            .if(obj.appearance.enableImportTapGestures) { view in
                view.onTapGesture(count: 2) {
                    viewModel.showBgPickerSheet = true
                }
                .onTapGesture(count: 1) {
                    viewModel.showImagePickerSheet1 = true
                }
            }
            .offset(y: obj.appearance.showSettingsSheet ? -110 : 0)
            .animation(.bouncy, value: obj.appearance.showSettingsSheet)
            .padding(-60)
    }
}

extension View {
    func titleViewModifier(obj: Object, normalScale: CGFloat) -> some View {
        self
            .scaleEffect(obj.appearance.showSettingsSheet || obj.appearance.isZoomActive ? 0 : normalScale)
            .opacity(obj.appearance.showSettingsSheet || obj.appearance.isZoomActive ? 0 : 1)
            .animation(.bouncy, value: obj.appearance.showSettingsSheet || obj.appearance.isZoomActive)
    }
}

extension View {
    func pillModifier(obj: Object, normalScale: CGFloat) -> some View {
        self
            .opacity(obj.appearance.showSettingsSheet || obj.appearance.showApplicationSettings ? 0.3 : 1)
            .animation(.bouncy, value: obj.appearance.showSettingsSheet || obj.appearance.showApplicationSettings)
            .disabled(obj.appearance.showSettingsSheet || obj.appearance.showApplicationSettings)
    }
}
