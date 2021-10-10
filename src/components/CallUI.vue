<template></template>

<script lang="ts">
import Vue from "vue";
import { UsersOnline } from "../Types";
export default Vue.extend({
  name: "CallUI",

  props: {
    isCallPublisher: Boolean,
    connectedUsers: {} as UsersOnline,

    startDesktopSharing: Function,
    stopDesktopSharing: Function,
    changeVideo: Function,
    changeAudio: Function,
    endCallSession: Function,
  },

  data: () => ({
    showVideoOptions: false,
    isDesktopShared: false,
    videoOn: true,
    audioOn: true,
    showConnectedUsers: false,
    fullScreen: false,

    videoIcon: "mdi-video",
    audioIcon: "mdi-microphone",
    screenMode: "mdi-fullscreen",
  }),

  methods: {
    desktopShare: function () {
      if (!this.isCallPublisher) {
        return;
      }

      console.log("Starting desktop share");
      if (!this.isDesktopShared) {
        this.startDesktopSharing();
      } else {
        this.stopDesktopSharing(this.videoOn);
      }

      this.isDesktopShared = !this.isDesktopShared;
    },

    changeVideoStatus: function () {
      if (!this.isCallPublisher || this.isDesktopShared) {
        return;
      }

      this.videoOn = !this.videoOn;

      if (this.videoOn) {
        this.videoIcon = "mdi-video";
      } else {
        this.videoIcon = "mdi-video-off";
      }

      this.changeVideo();
    },

    changeAudioStatus: function () {
      if (this.audioOn) {
        this.audioIcon = "mdi-microphone-off";
      } else {
        this.audioIcon = "mdi-microphone";
      }

      this.audioOn = !this.audioOn;
      this.changeAudio(this.audioOn);
    },

    changeFullScreenStatus: function () {
      if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen();
      } else if (document.exitFullscreen) {
        document.exitFullscreen();
      }

      this.fullScreen = !this.fullScreen;
    },
  },
});
</script>