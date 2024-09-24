//
//  ContentView.swift
//  LearnMapKit
//
//  Created by Jacky Jack on 05/06/2024.
//

import SwiftUI
import MapKit
import Collections

struct ContentView: View {
    
    @State private var region = MKCoordinateRegion()
    @State private var isImporting = false
    
    @Binding var net_config: NetworkConfigure
    @EnvironmentObject var flightState: FlightState
    @Environment(\.openWindow) private var openWindow
    
    let initialPosition: MapCameraPosition = {
        let center = CLLocationCoordinate2D(latitude: 55.90159, longitude:-3.53154)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: center, span: span)
        return .region(region)
    }()
    
    var body: some View {
        
        VStack {
            Map(initialPosition: initialPosition) {
                ForEach(flightState.flight) { flight in
                    Annotation(flight.ICAOName,
                               coordinate: CLLocationCoordinate2D(
                                latitude: flight.lat,
                                longitude:flight.long)
                    ) {
                        
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
                            Text("\(flight.ICAOName)").font(.body)
                        }
                    }.annotationTitles(.hidden)
                }
            }
            .padding()
            .border(.green)
            .layoutPriority(1)
            .mapStyle(.hybrid(elevation: .realistic))
            /*.toolbar {
                ToolbarItem() {
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import file", systemImage: "square.and.arrow.down")
                    }
                }*//*
                ToolbarItem {
                    Button {
                        openWindow(id: "net-config")
                    } label: {
                        Label("Network config", systemImage: "network")
                    }
                }
            }*/ /*.fileImporter(isPresented: $isImporting, allowedContentTypes: [.text], allowsMultipleSelection: false) {
                result in switch result {
                case .success(let files):
                    print(files)
                case .failure(let error):
                    print(error)
                }
            }*/
            
            
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
