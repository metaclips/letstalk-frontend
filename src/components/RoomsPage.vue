<template>
  <v-row no-gutters style="justify-content: center">
    <v-col class="my-3" cols="12" sm="10">
      <v-text-field
        rounded
        filled
        prepend-inner-icon="mdi-magnify"
        flat
        placeholder="Search for conversations"
      ></v-text-field>
    </v-col>

    <v-col cols="12" class="text-center">
      <v-btn
        :outlined="currentRoomFilter == joinedRoomFilter.All"
        @click="currentRoomFilter = joinedRoomFilter.All"
        text
        rounded
        >{{ joinedRoomFilter.All }}</v-btn
      >

      <v-btn
        :outlined="currentRoomFilter == joinedRoomFilter.Read"
        @click="currentRoomFilter = joinedRoomFilter.Read"
        text
        rounded
        >{{ joinedRoomFilter.Read }}</v-btn
      >

      <v-btn
        :outlined="currentRoomFilter == joinedRoomFilter.Unread"
        @click="currentRoomFilter = joinedRoomFilter.Unread"
        text
        rounded
        >{{ joinedRoomFilter.Unread }}</v-btn
      >
    </v-col>

    <v-col cols="12">
      <v-subheader>
        <b>Discussions</b>
      </v-subheader>
    </v-col>

    <v-col cols="12">
      <v-container style="height: 70vh" class="overflow-y-auto" cols="12">
        <v-list nav tile dense three-line>
          <v-list-item-group v-model="roomIndex" mandatory>
            <v-list-item
              v-for="(joinedRoom, index) in filteredRooms"
              :key="index"
              @click="
                loadChatContent(
                  filteredRooms[index]._id,
                  filteredRooms[index].messageCount
                )
              "
            >
              <v-list-item-avatar>
                <v-badge
                  bordered
                  overlap
                  bottom
                  dot
                  :value="
                    unreadRoomMessages[joinedRoom.roomID]
                      ? unreadRoomMessages[joinedRoom.roomID]
                      : false
                  "
                  offset-x="10"
                  offset-y="10"
                >
                  <v-avatar size="30">
                    <v-img
                      :src="
                        joinedRoom.roomIcon
                          ? joinedRoom.icon
                          : require('../assets/unilag.svg')
                      "
                    ></v-img>
                  </v-avatar>
                </v-badge>
              </v-list-item-avatar>

              <v-list-item-content>
                <v-list-item-title>
                  <v-row no-gutters>
                    <v-col
                      cols="auto"
                      class="d-inline-block text-truncate"
                      style="width: 70%"
                      justify="start"
                      align="start"
                      >{{ joinedRoom.roomName }}</v-col
                    >
                  </v-row>
                </v-list-item-title>

                <v-list-item-subtitle
                  align="left"
                  class="d-inline-block text-truncate"
                  >{{
                    filteredRooms[index].previewMessage
                      ? filteredRooms[index].previewMessage
                      : ""
                  }}</v-list-item-subtitle
                >
              </v-list-item-content>
            </v-list-item>
          </v-list-item-group>
        </v-list>
      </v-container>
    </v-col>
  </v-row>
</template>

<script lang="ts">
import Vue from "vue";
import { Prop } from "vue/types/options";

import { JoinedRoom, UnreadRooms } from "../Types";
import { WSMessageType, JoinedRoomsFilter } from "../Constants";

export default Vue.extend({
  name: "RoomsPage",

  props: {
    joinedRooms: Array as Prop<JoinedRoom[]>,
    unreadRoomMessages: {} as Prop<UnreadRooms>,

    sendWSMessage: Function,
    changeViewedRoomIndex: Function,

    indexOfCurrentViewedRoom: Number,
  },

  data: () => ({
    joinedRoomFilter: JoinedRoomsFilter,
    currentRoomFilter: JoinedRoomsFilter.All,

    roomIndex: -1,
    filteredRooms: [] as JoinedRoom[],
  }),

  methods: {
    loadChatContent: function (roomID: string, count: number) {
      // TODO: CHeck here
      console.log(count);

      const message = {
        msgType: WSMessageType.RequestMessages,
        roomID: roomID,
        skip: 0,
        limit: 15,
      };

      console.log(message);
      this.sendWSMessage(JSON.stringify(message));
    },

    filterRooms: function (retrieveOnlyUnread: boolean): JoinedRoom[] {
      const joinedRooms: JoinedRoom[] = [];

      this.joinedRooms.forEach((joinedRoom: JoinedRoom) => {
        let isUnread = this.unreadRoomMessages[joinedRoom._id];
        if (!isUnread) {
          isUnread = false;
        }
        if (isUnread == retrieveOnlyUnread) {
          joinedRooms.push(joinedRoom);
        }
      });

      return joinedRooms;
    },

    roomFilterWatcher: function () {
      switch (this.currentRoomFilter) {
        case this.joinedRoomFilter.Unread:
          this.filteredRooms = this.filterRooms(true);
          return;
        case this.joinedRoomFilter.Read:
          this.filteredRooms = this.filterRooms(false);
          return;
      }

      this.filteredRooms = this.joinedRooms;
    },
  },

  watch: {
    roomIndex: async function () {
      console.log("roomIndex");
      for (let i = 0; i < this.joinedRooms.length; i++) {
        if (
          this.joinedRooms[i]._id === this.filteredRooms[this.roomIndex]._id
        ) {
          console.log("not yet");
          this.changeViewedRoomIndex(i);
          return;
        }
      }

      console.log("didint work");
      this.changeViewedRoomIndex(0);

      console.log("roomIndex done");
    },

    joinedRooms: function () {
      console.log("joinedRooms");
      this.roomFilterWatcher();
    },

    currentRoomFilter: function () {
      console.log("currentRoomFilter");
      this.roomFilterWatcher();
    },
  },

  created() {
    this.filteredRooms = this.joinedRooms;
  },
});
</script>

<style>
.button_default {
  font-family: sans-serif;
  font-weight: 600;
  font-size: small;
}
</style>