//
//  ScrubbingPlayerView.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import SwiftUI
import ComposableArchitecture

struct ScrubbingPlayerView: View {
  let store: Store<ScrubbingPlayerState, ScrubbingPlayerAction>
  let timer = Timer.publish(every: 0.001, on: .main, in: .common).autoconnect()
  
  @State var isAutoScrollMode = false
  @State var showAssetList = false
  
  @State var artwork: Image = Image.artwork
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        Button {
          showAssetList = true
        } label: {
          Text("Asset List")
        }
        Spacer()
        artwork
          .resizable()
          .aspectRatio(
            nil,
            contentMode: .fit)
          .padding()
          .layoutPriority(1)
        
        Spacer()
        
        PlayerControlView
          .padding(.bottom)
      }
      .onAppear {
        viewStore.send(.onAppear)
      }
      .onDisappear() {
        viewStore.send(.onDisappear)
      }
      .sheet(isPresented: $showAssetList) {
        MusicAssetListView(
          store: self.store.scope(
            state: \.musicAssetListState,
            action: ScrubbingPlayerAction.musicAssetListAction
          ),
          showView: $showAssetList)
      }
      .onChange(of: viewStore.artwork) { newImage in
        if let data = newImage {
          self.artwork = Image(uiImage: UIImage(data: data as Data)!)
        }
        else {
          self.artwork = Image.artwork
        }
      }
    }
  }
  
  
  private var PlayerControlView: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        PlaybackScrollView(store: self.store)
          .padding(.bottom)
        
        HStack {
          Text(viewStore.playerInfo.playerTime.elapsedText)
          
          Spacer()
          
          Text(viewStore.playerInfo.playerTime.remainingText)
        }
        .font(.system(size: 14, weight: .semibold))
        .padding()
        
        
        AudioControlButtonsView
        //.disabled(!viewModel.isPlayerReady)
          .padding(.bottom)
        
        StateButtonView(
          text: "Auto Scroll",
          action: { press in
            if viewStore.playerInfo.isPlaying {
              viewStore.send(.playPauseTapped(viewStore.playerInfo))
            }
            viewStore.send(.setAutoScrubbing(on: press))
//            if (!self.isAutoScrollMode && press) {
//              viewStore.send(.startFileRecording(fileName: "test.raw"))
//            }
//            else {
//              viewStore.send(.stopFileRecording)
//            }
            self.isAutoScrollMode = press
          })
        .font(.system(size: 20))
        
      }
//      .onReceive(timer) { _ in
//        if isAutoScrollMode {
//          if viewStore.progressViewOffset.x <= 390 {
//            let offset = CGPoint(x: viewStore.progressViewOffset.x + 0.085, y: viewStore.progressViewOffset.y)
//            viewStore.send(.setProgressViewOffset(offset: offset))
//          }
//          else {
//            viewStore.send(.stopFileRecording)
//            //viewStore.send(.setProgressViewOffset(offset: .zero))
//          }
//        }
//      }
      //.padding(.horizontal)
    }
  }
  
  private var AudioControlButtonsView: some View {
    WithViewStore(self.store) { viewStore in
      HStack(spacing: 20) {
        Spacer()
        
        Button {
          //viewModel.skip(forwards: false)
          print("backward")
          viewStore.send(.seek(time: -10, relative: true))
        } label: {
          Image.backward
        }
        .font(.system(size: 32))
        
        Spacer()
        
        Button {
          print("play / pause")
          viewStore.send(.playPauseTapped(viewStore.playerInfo))
        } label: {
          viewStore.playerInfo.isPlaying ? Image.pause : Image.play
        }
        .frame(width: 40)
        .font(.system(size: 45))
        
        Spacer()
        
        Button {
          print("forward")
          viewStore.send(.seek(time: 10, relative: true))
        } label: {
          Image.forward
        }
        .font(.system(size: 32))
        
        Spacer()
      }
      .foregroundColor(.primary)
      .padding(.vertical, 20)
      .frame(height: 58)
      
      Spacer()
    }
  }
}

fileprivate struct SliderBarView: View {
  @Binding var value: Double
  //@State private var isEditing = false
  @Binding var isEditing: Bool
  
  
  var body: some View {
    VStack {
      Slider(
        value: $value,
        in: 0...100,
        onEditingChanged: { editing in
          isEditing = editing
          
        }
      )
      Text("\(value)")
        .foregroundColor(isEditing ? .red : .blue)
    }
  }
}

struct PlaybackScrollView: View {
  let store: Store<ScrubbingPlayerState, ScrubbingPlayerAction>
  
  @State private var contentOffset: CGPoint = .zero
  @State private var screenSize: CGRect = UIScreen.main.bounds
  @State private var orientation = UIDeviceOrientation.unknown
  
  @State private var scrollVelocity: CGFloat = CGFloat(0)
  @State private var nowScrubbing: Bool = false
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        Text("\(contentOffset.x / screenSize.width * 100.0) off: \(Int(contentOffset.x))")
        ZStack {
          ScrollableView(
            self.$contentOffset,
            animationDuration: 0.5,
            axis: .horizontal,
            scrollVelocity: $scrollVelocity,
            beginDragging: { self.nowScrubbing = true },
            endDragging: {_ in self.nowScrubbing = false }) {
              ZStack {
                Color.clear
                  .frame(width: screenSize.width*2, height: 60)
                HStack(spacing: 0) {
                  Color.black
                    .frame(width: screenSize.width/2, height: 60)
                  Color.green
                    .frame(width: screenSize.width, height: 60)
                  Color.black
                    .frame(width: screenSize.width/2, height: 60)
                    .id(3)  //Set the Id
                }
              }
            }
          
          VStack(spacing: 0) {
            Color.black
              .frame(width: 3, height: 100)
          }
        }
      }
      .onRotate { newOrientation in
        orientation = newOrientation
        screenSize = UIScreen.main.bounds
        print("screen: \(screenSize)")
        viewStore.send(.setProgressViewWidth(width: screenSize.width))
      }
      .onChange(of: nowScrubbing) { newStateScrubbing in
        print("scrubbing: \(newStateScrubbing) \(viewStore.isScrubbingNow)")
           
        if newStateScrubbing && viewStore.playerInfo.isPlaying {
          viewStore.send(.playPauseTapped(viewStore.playerInfo))
        }
        
        viewStore.send(.setScrubbing(on: newStateScrubbing))
      }
      .onChange(of: viewStore.progressViewOffset) { offset in
        if !nowScrubbing {
          self.contentOffset = offset
        }
      }
      .onChange(of: contentOffset) { offset in
        if viewStore.isScrubbingNow {
          viewStore.send(.setScrubbingPropertiesWithView(offset: offset.x, velocity: scrollVelocity))
        }
      }
    }
  }
}


fileprivate struct StateButtonView: View {
  @State var press = false
  var text: String
  var action: (Bool)-> Void
  
  var body: some View {
    Button {
      press = !press
      action(press)
    } label: {
      Text(text)
    }
  }
}



fileprivate struct ProgressBarView: View {
  @Binding var value: Double
  
  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
          .foregroundColor(Color(UIColor.systemTeal))
        
        Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
          .foregroundColor(Color(UIColor.blue))
          .animation(.linear)
      }.cornerRadius(22)
    }
  }
}

//struct ScrubbingPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        ScrubbingPlayerView()
//    }
//}
