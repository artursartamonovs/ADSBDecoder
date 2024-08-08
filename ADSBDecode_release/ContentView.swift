//
//  ContentView.swift
//  LearnMapKit
//
//  Created by Jacky Jack on 05/06/2024.
//

import SwiftUI
import MapKit
import Collections



struct FlightView: View {
    
    var evilClass: FlightState
    
    var body: some View {
        //let i = evilClass.flight.count
        let pos = CLLocationCoordinate2D(latitude: 55.80159, longitude:-3.13154)
        Map() {
            ForEach(0..<10, id:\.self) {i in
                Annotation("plane\(i)", coordinate: pos) {
                ZStack {
                 RoundedRectangle(cornerRadius: 10)
                 .fill(.background)
                 RoundedRectangle(cornerRadius: 10)
                 .stroke(.secondary,lineWidth: 5)
                 Image(systemName:"airplane.circle.fill")
                 .resizable()
                 .frame(width:20,height: 20)
                 }
                }//.annotationTitles(.hidden)
            }
        }
    }
}

struct ContentView: View {
    
    @State private var region = MKCoordinateRegion()
    @State private var isImporting = false
    
    @Binding var pos_queue: Deque<ADSBLocation>
    @Binding var net_config: NetworkConfigure
    @EnvironmentObject var evilClass: FlightState
    @Environment(\.openWindow) private var openWindow
    
    
    let initialPosition: MapCameraPosition = {
        let center = CLLocationCoordinate2D(latitude: 55.90159, longitude:-3.53154)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: center, span: span)
        return .region(region)
    }()
    
    let position1 = CLLocationCoordinate2D(latitude: 55.80159, longitude:-3.53154)
    let position2 = CLLocationCoordinate2D(latitude: 55.99159, longitude:-3.53154)
    let position3 = CLLocationCoordinate2D(latitude: 55.80159, longitude:-3.43154)
    let position4 = CLLocationCoordinate2D(latitude: 55.80159, longitude:-3.63154)
    
    var body: some View {
        
        VStack {
            HStack(alignment: .top) {
                Button("1") {
                    print("Pressed 1")
                }
                Button("2") {
                    print("Pressed 2")
                }
                Button("3") {
                    print("Pressed 3")
                }
                Button("4") {
                    print("Pressed 4")
                }
                Button("5") {
                    print("Pressed 5")
                }
                Button("6") {
                    print("Pressed 6")
                }
                Button("7") {
                    print("Pressed 7")
                    //print(evilClass.update_postions.count)
                }
            }
            .border(.blue)
            //.frame(maxWidth:.infinity)
            //.padding()
            
            Map(initialPosition: initialPosition) {
                ForEach(self.evilClass.flight.sorted(by: { $0.key < $1.key} ), id:\.key) { k in
                    Annotation("\(k.key)", coordinate: CLLocationCoordinate2D(latitude: self.evilClass.flight[k.key]!.lat, longitude:self.evilClass.flight[k.key]!.long)) {
                            VStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.background)
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.secondary,lineWidth: 5)
                                    Image(systemName:"airplane.circle.fill")
                                        .resizable()
                                        .frame(width:20,height: 20)
                                }
                                Text("\(k.value.ICAOName)")
                            }
                        }.annotationTitles(.hidden)
                }
            }
            .padding()
            .border(.green)
            .layoutPriority(1)
            .mapStyle(.hybrid(elevation: .realistic))
            .toolbar {
                ToolbarItem() {
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import file", systemImage: "square.and.arrow.down")
                    }
                }
                ToolbarItem {
                    Button {
                        openWindow(id: "net-config")
                    } label: {
                        Label("Network config", systemImage: "network")
                    }
                }
            } .fileImporter(isPresented: $isImporting, allowedContentTypes: [.text], allowsMultipleSelection: false) {
                result in switch result {
                case .success(let files):
                    print(files)
                case .failure(let error):
                    print(error)
                }
            }
            
            
        }
        .padding()
        .border(.red)
        .layoutPriority(1)
    }
    
    func mapAction() {
        print("This is called")
    }
    
}

//#Preview {
    //ContentView(pos_queue: pos_queue)
//}
