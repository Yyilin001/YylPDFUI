# YylPDFUI

✨ 一个基于 PDFKit 的SwiftUI组件库。

---

## 安装 Installation

### 使用 Swift Package Manager

在 Xcode 中：

1. 点击菜单栏 `File > Add Packages...`
2. 输入项目地址：https://github.com/Yyilin001/YylPDFUI.git
3. 选择最新版本并添加到你的项目中

---


## 演示
![演示](https://github.com/Yyilin001/YylPDFUI/blob/main/image.png)

## 使用示例 Usage


```swift

import SwiftUI
import YylPDFUI
import PDFKit
struct ContentView: View {
    @State private var pdfProxy = PDFProxy()
    @State private var thums: [PDFThumbnail] = []
    @State private var selectedMode: PDFDisplayMode = .singlePageContinuous
    var body: some View {
        if pdfProxy.pdfDocument != nil {
            YylPDFView()
                .environment(pdfProxy)
                .safeAreaInset(edge: .top) {
                    createTop()
                }
                .safeAreaInset(edge: .bottom) {
                    createbBottom()
                }
                .overlay(alignment: .trailing) {
                    createThums()
                }
        } else {
            ProgressView()
                .task {
                    openPDFInBundle(named: "apple-platform-security-guide-cn")
                }
        }
    }
    @ViewBuilder
    private func createThums() -> some View {
        if thums.isEmpty {
            ProgressView()
                .task {
                    thums = pdfProxy.generateAllThumbnailsStruct(size: CGSize(width: 80, height: 120))
                }
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(thums, id: \.pageIndex) { item in
                        Button {
                            pdfProxy.goToPage(item.pageIndex)
                        } label: {
                            Image(uiImage: item.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 120)
                        }
                    }
                }
            }.padding(.vertical,100)
        }
    }

    private func createTop() -> some View {
        ScrollView(.horizontal) {
            HStack {
                Button {
                    guard pdfProxy.maxIndex > 0 else { return }
                    let index = Int.random(in: 0 ..< pdfProxy.maxIndex)
                    pdfProxy.goToPage(index)
                } label: {
                    Text("随机跳转")
                }
                Picker("显示模式", selection: $selectedMode) {
                           Text("单页翻页").tag(PDFDisplayMode.singlePage)
                           Text("单页连续").tag(PDFDisplayMode.singlePageContinuous)
                           Text("双页翻页").tag(PDFDisplayMode.twoUp)
                           Text("双页连续").tag(PDFDisplayMode.twoUpContinuous)
                       }
                       .pickerStyle(.segmented) // 可以改成 WheelPicker 或 Menu
                       .onChange(of: selectedMode) {_, newMode in
                           pdfProxy.setDisplayMode(newMode)
                       }
                
            }.padding(.horizontal)
        }
    }

    private func createbBottom() -> some View {
        ScrollView(.horizontal) {
            HStack {
                Button {
                } label: {
                    Text("当前页面\(pdfProxy.currentIndex)")
                }
                
                Button {
                    pdfProxy.setDisplayDirection(.horizontal)
                } label: {
                    Text("切换到水平")
                }
                Button {
                    pdfProxy.setDisplayDirection(.vertical)
                } label: {
                    Text("切换到垂直")
                }
                
                Button {
                    pdfProxy.setAutoScales(true)
                } label: {
                    Text("自动缩放")
                }
             
                
            }.padding(.horizontal)
        }
    }

    private func openPDFInBundle(named name: String) {
        if let url = Bundle.main.url(forResource: name, withExtension: "pdf") {
            if let doc = PDFDocument(url: url) {
                pdfProxy.pdfDocument = doc
            }
        }
    }
}

#Preview {
    ContentView()
}


```
