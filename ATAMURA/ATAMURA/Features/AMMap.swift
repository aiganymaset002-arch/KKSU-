//
//  AMMap.swift
//  ATA MURA
//
//  ATA MURA MAP: интерактивная карта Казахстана. Регион → личности, памятники, шахты,
//  поселения, легенды, исследования, школьные проекты, предприятия и изобретения региона.
//

import SwiftUI
import MapKit

struct AMMapView: View {
    var body: some View {
        NavigationStack { AMMapScreen() }
    }
}

struct AMMapScreen: View {
    @EnvironmentObject private var store: AMStore
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.0, longitude: 67.5),
        span: MKCoordinateSpan(latitudeDelta: 18, longitudeDelta: 30)))
    @State private var kind: AMPlaceKind?
    @State private var selectedRegion: AMRegion?
    @State private var selectedPlace: AMPlace?
    @State private var showAdd = false

    private var places: [AMPlace] {
        store.visiblePlaces.filter { kind == nil || $0.kind == kind }
    }

    var body: some View {
        Map(position: $position) {
            ForEach(AMRegion.allCases) { region in
                Annotation(region.title, coordinate: region.coordinate) {
                    Button {
                        selectedRegion = region
                    } label: {
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.title3)
                            .foregroundStyle(.white, AMTheme.skyDeep)
                            .padding(4)
                            .background(AMTheme.skyDeep.opacity(0.85), in: Circle())
                    }
                    .accessibilityLabel(region.title)
                }
            }
            ForEach(places) { place in
                Annotation(place.title, coordinate: place.coordinate) {
                    Button {
                        selectedPlace = place
                    } label: {
                        Image(systemName: place.kind.icon)
                            .font(.caption.bold())
                            .foregroundStyle(AMTheme.night)
                            .padding(7)
                            .background(AMTheme.gold, in: Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                    .accessibilityLabel("\(place.kind.title): \(place.title)")
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .top) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    chip(L("common.all"), icon: "square.grid.2x2", selected: kind == nil) { kind = nil }
                    ForEach(AMPlaceKind.allCases) { option in
                        chip(option.title, icon: option.icon, selected: kind == option) { kind = option }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .background(.ultraThinMaterial)
        }
        .navigationTitle("ATA MURA MAP")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button { showAdd = true } label: { Image(systemName: "mappin.and.ellipse") }
                .accessibilityLabel(L("create.place"))
        }
        .sheet(item: $selectedRegion) { region in
            NavigationStack { AMRegionView(region: region) }
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedPlace) { place in
            NavigationStack { AMPlaceDetailView(place: place) }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack { AMPlaceEditorView() }
        }
    }

    private func chip(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .foregroundStyle(selected ? .white : AMTheme.skyDeep)
                .background(selected ? AMTheme.skyDeep : Color(.systemBackground), in: Capsule())
        }
    }
}

/// Всё о регионе: места по категориям, публикации, проекты, музей.
struct AMRegionView: View {
    @EnvironmentObject private var store: AMStore
    let region: AMRegion

    var body: some View {
        let places = store.visiblePlaces.filter { $0.region == region }
        let posts = store.approvedPosts.filter { $0.region == region }
        let projects = store.db.projects.filter { $0.region == region && $0.status == .approved }
        let museum = store.db.museum.filter { $0.region == region && $0.status == .approved }
        List {
            ForEach(AMPlaceKind.allCases) { kind in
                let items = places.filter { $0.kind == kind }
                if !items.isEmpty {
                    Section(kind.title) {
                        ForEach(items) { place in
                            NavigationLink { AMPlaceDetailView(place: place) } label: {
                                Label(place.title, systemImage: kind.icon)
                            }
                        }
                    }
                }
            }
            if !posts.isEmpty {
                Section("TARIH") {
                    ForEach(posts) { post in
                        NavigationLink { AMPostDetailView(postId: post.id) } label: { Label(post.title, systemImage: post.type.icon) }
                    }
                }
            }
            if !projects.isEmpty {
                Section(L("placekind.invention")) {
                    ForEach(projects) { project in
                        NavigationLink { AMProjectDetailView(projectId: project.id) } label: { Label(project.title, systemImage: "lightbulb") }
                    }
                }
            }
            if !museum.isEmpty {
                Section("Digital Museum") {
                    ForEach(museum) { item in
                        NavigationLink { AMMuseumDetailView(itemId: item.id) } label: { Label(item.title, systemImage: "building.columns") }
                    }
                }
            }
            if places.isEmpty && posts.isEmpty && projects.isEmpty && museum.isEmpty {
                AMEmptyState(icon: "map", text: L("map.regionEmpty"))
            }
            Section {
                NavigationLink { AMPlaceEditorView(region: region) } label: { Label(L("create.place"), systemImage: "plus") }
                NavigationLink { AMPostEditorView(type: .place) } label: { Label(L("map.writeAbout"), systemImage: "square.and.pencil") }
            }
        }
        .navigationTitle(region.title)
    }
}

struct AMPlaceDetailView: View {
    @EnvironmentObject private var store: AMStore
    let place: AMPlace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    AMTag(text: place.kind.title, icon: place.kind.icon)
                    AMTag(text: place.region.title, icon: "mappin", color: .green)
                    if !place.period.isEmpty { AMTag(text: place.period, icon: "clock") }
                }
                if let image = place.image { AMImageView(data: image, height: 220) }
                Text(place.title).font(.title2.bold())
                AMBodyText(text: place.summary)
                AMSpeakButton(text: place.title + ". " + place.summary, id: place.id)
                Map(initialPosition: .region(MKCoordinateRegion(center: place.coordinate,
                                                                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)))) {
                    Marker(place.title, systemImage: place.kind.icon, coordinate: place.coordinate)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                let topics = store.db.topics.filter { place.topicIds.contains($0.id) }
                if !topics.isEmpty {
                    AMSectionHeader(title: L("tarih.linked"), icon: "link")
                    ForEach(topics) { topic in
                        NavigationLink { AMTopicView(topic: topic) } label: { AMTag(text: topic.title, icon: "books.vertical") }
                    }
                }
                Button {
                    let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
                    item.name = place.title
                    item.openInMaps()
                } label: {
                    Label(L("map.openInMaps"), systemImage: "arrow.triangle.turn.up.right.diamond")
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle(place.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AMPlaceEditorView: View {
    @EnvironmentObject private var store: AMStore
    @Environment(\.dismiss) private var dismiss
    @State private var place: AMPlace
    @State private var latitude: String
    @State private var longitude: String
    @State private var saved = false

    init(region: AMRegion = .astana) {
        _place = State(initialValue: AMPlace(title: "", summary: "", kind: .monument, region: region,
                                             latitude: region.coordinate.latitude, longitude: region.coordinate.longitude))
        _latitude = State(initialValue: String(format: "%.4f", region.coordinate.latitude))
        _longitude = State(initialValue: String(format: "%.4f", region.coordinate.longitude))
    }

    var body: some View {
        Form {
            Section {
                TextField(L("editor.title"), text: $place.title)
                Picker(L("place.kind"), selection: $place.kind) {
                    ForEach(AMPlaceKind.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                }
                Picker(L("common.region"), selection: $place.region) {
                    ForEach(AMRegion.allCases) { Text($0.title).tag($0) }
                }
                .onChange(of: place.region) { _, region in
                    latitude = String(format: "%.4f", region.coordinate.latitude)
                    longitude = String(format: "%.4f", region.coordinate.longitude)
                }
                TextField(L("place.period"), text: $place.period)
                AMTextArea(title: L("place.summary"), text: $place.summary)
                AMSinglePhotoPicker(title: L("common.addPhoto"), image: $place.image)
            }
            Section {
                TextField(L("place.lat"), text: $latitude).keyboardType(.decimalPad)
                TextField(L("place.lon"), text: $longitude).keyboardType(.decimalPad)
            } header: {
                Text(L("place.coordinates"))
            } footer: {
                Text(L("place.coordinatesHint"))
            }
            Section {
                Button(L("editor.publish")) {
                    place.latitude = Double(latitude.replacingOccurrences(of: ",", with: ".")) ?? place.region.coordinate.latitude
                    place.longitude = Double(longitude.replacingOccurrences(of: ",", with: ".")) ?? place.region.coordinate.longitude
                    place.topicIds = store.suggestedTopics(for: place.title + " " + place.summary).map(\.id)
                    store.addPlace(place)
                    saved = true
                }
                .disabled(place.title.isEmpty || place.summary.isEmpty)
            }
        }
        .navigationTitle(L("create.place"))
        .alert(store.isStaff ? L("editor.published") : L("editor.sent"), isPresented: $saved) {
            Button("OK") { dismiss() }
        }
    }
}
