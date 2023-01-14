//
//  ContentView.swift
//  GetGeocodeSample
//
//  Created by 花形春輝 on 2023/01/14.
//

import SwiftUI
import MapKit

struct ContentView: View {
    /// ViewModel
    @StateObject var viewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            HStack {
                // 場所入力欄
                TextField("", text: $viewModel.location)
                    .padding(5)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.primary.opacity(0.6), lineWidth: 0.3))
                    .onChange(of: viewModel.location) { newValue in
                        viewModel.onSearchLocation()
                    }
                
                // 検索ボタン
                Image(systemName: "magnifyingglass")
                    .imageScale(.large)
                    .onTapGesture {
                        viewModel.onSearch()
                    }
            }
            
            if viewModel.completions.count > 0 {
                // 検索候補
                List(viewModel.completions , id: \.self) { completion in
                    HStack{
                        VStack(alignment: .leading) {
                            Text(completion.title)
                            Text(completion.subtitle)
                                .foregroundColor(Color.primary.opacity(0.5))
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture{
                        viewModel.onLocationTap(completion)
                    }
                }
            } else {
                HStack {
                    // 場所の詳細情報
                    Text(viewModel.locationDetail)
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

class ContentViewModel : NSObject, ObservableObject, MKLocalSearchCompleterDelegate{
    /// 位置情報検索クラス
    var completer = MKLocalSearchCompleter()
    /// 場所
    @Published var location = ""
    /// 検索クエリ
    @Published var searchQuery = ""
    /// 位置情報検索結果
    @Published var completions: [MKLocalSearchCompletion] = []
    /// 場所の詳細情報
    @Published var locationDetail = ""
    
    override init(){
        super.init()
        
        // 検索情報初期化
        completer.delegate = self
        
        // 場所のみ(住所を省く)
        completer.resultTypes = .pointOfInterest
    }
    
    /// 住所変更時
    func onSearchLocation() {
        // マップ表示中の目的地と同じなら何もしない
        if searchQuery == location {
            completions = []
            return
        }
        
        // 検索クエリ設定
        searchQuery = location
        
        // 場所が空の時、候補もクリア
        if searchQuery.isEmpty {
            completions = []
        } else {
            if completer.queryFragment != searchQuery {
                completer.queryFragment = searchQuery
            }
        }
    }
    
    /// 検索結果表示
    /// - Parameter completer: 検索結果の場所一覧
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            if self.searchQuery.isEmpty {
                self.completions = .init()
            } else {
                self.completions = completer.results
            }
        }
    }
    
    /// 場所をタップ
    /// - Parameter completion: タップされた場所
    func onLocationTap(_ completion:MKLocalSearchCompletion){
        DispatchQueue.main.async {
            // 場所を選択
            self.location = completion.title
            self.searchQuery = self.location
            
            // 検索
            self.onSearch()
        }
    }
    
    /// 場所の詳細情報を検索
    func onSearch(){
        // 検索結果クリア
        completions = []
        locationDetail = ""
        
        CLGeocoder().geocodeAddressString(self.location) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.locationDetail += "国 : " + (placemark.country ?? "")
                    self.locationDetail += "\n郵便番号 : " + (placemark.postalCode ?? "")
                    self.locationDetail += "\n都道府県 : " + (placemark.administrativeArea ?? "")
                    self.locationDetail += "\n市区町村 : " + (placemark.locality ?? "")
                    self.locationDetail += "\n地名 : " + (placemark.thoroughfare ?? "")
                    self.locationDetail += "\n番地 : " + (placemark.subThoroughfare ?? "")
                    self.locationDetail += "\n経度 : " + String(placemark.location?.coordinate.longitude ?? 0)
                    self.locationDetail += "\n緯度 : " + String(placemark.location?.coordinate.latitude ?? 0)
                }
            }
        }
    }
}
