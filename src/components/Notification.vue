<template>
  <v-row class="fill-height">
    <v-col cols="12" class="my-auto">
      <v-row>
        <v-col cols="3"></v-col>

        <v-col cols="6">
          <v-card height="min-content" outlined shaped>
            <v-row class="mx-5">
              <v-col cols="12">
                <v-card-title>
                  <b>Notifications</b>
                </v-card-title>
              </v-col>

              <v-col cols="12">
                <v-divider></v-divider>
              </v-col>

              <v-col cols="12">
                <v-card-text>
                  <v-container
                    fluid
                    style="max-height: 72vh"
                    class="overflow-y-auto"
                  >
                    <v-card-subtitle v-if="!joinRequests"
                      >No Notifications</v-card-subtitle
                    >
                    <v-card
                      v-for="(joinRequest, index) in joinRequests"
                      :key="index"
                      flat
                    >
                      <v-card-text
                        >{{ joinRequest.createdByUserDetails }} wants you to
                        join room "{{ joinRequest.roomName }}"</v-card-text
                      >
                      <v-card-actions>
                        <v-btn @click="joinRoom(true, index)" text color="green"
                          >Join</v-btn
                        >

                        <v-btn @click="joinRoom(false, index)" text color="red"
                          >Reject</v-btn
                        >
                      </v-card-actions>
                    </v-card>
                  </v-container>
                </v-card-text>
              </v-col>

              <v-col cols="12"></v-col>
            </v-row>
          </v-card>
        </v-col>

        <v-col cols="3"></v-col>
      </v-row>
    </v-col>
  </v-row>
</template>

<script lang="ts">
import Vue from "vue";
import { Prop } from "vue/types/options";

import { JoinRequest } from "../Types";

export default Vue.extend({
  props: {
    joinRoom: Function,
    joinRequests: Array as Prop<JoinRequest[]>,
  },
  data: () => ({}),
});
</script>