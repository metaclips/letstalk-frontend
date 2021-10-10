<template>
  <v-dialog persistent width="400px">
    <v-card>
      <v-card-text>
        <div align="center" justify="center">
          <v-row>
            <v-col cols="12">
              <span>{{ dialogError }}</span>
            </v-col>
            <v-col>
              <v-row justify="center">
                <v-btn text depressed color="green" @click="dialog = false">
                  Close
                </v-btn>
                <v-btn
                  depressed
                  text
                  color="red"
                  v-if="socketClosed"
                  @click="connectWebsocket"
                >
                  Reconnect
                </v-btn>
              </v-row>
            </v-col>
          </v-row>
        </div>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script lang="ts">
"use strict";

import Vue from "vue";

export default Vue.extend({
  props: {
    socketClosed: Boolean,
    dialogError: String,
    connectWebsocket: Function,
  },
  data: () => ({}),
});
</script>