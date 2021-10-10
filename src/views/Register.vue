<template>
  <v-app>
    <v-main>
      <v-container fluid class="fill-height">
        <v-row fill-height>
          <v-col class="mx-auto" cols="12" sm="4">
            <v-img
              class="mx-auto"
              src="../assets/unilag.svg"
              :height="$vuetify.breakpoint.smAndDown ? '200' : '300'"
              :width="$vuetify.breakpoint.smAndDown ? '200' : '300'"
              contain
            ></v-img>
          </v-col>

          <v-col cols="12">
            <v-form v-model="dataIsValid">
              <v-row class="fill-height" justify="center" align="center">
                <v-col class="text-center" cols="12">
                  <span class="text-center mx-auto"
                    >Welcome to the University of Lagos chatting platform</span
                  >
                </v-col>

                <v-col cols="12" sm="3" md="4">
                  <v-text-field
                    v-model="email"
                    outlined
                    filled
                    type="email"
                    required
                    placeholder="Email Address"
                    :rules="emailRules"
                    :disabled="detailsDisabled"
                  ></v-text-field>

                  <v-text-field
                    type="password"
                    v-model="password"
                    outlined
                    filled
                    required
                    :rules="fillInputRules"
                    placeholder="Password"
                    :disabled="detailsDisabled"
                  ></v-text-field>

                  <v-text-field
                    v-model="firstName"
                    outlined
                    filled
                    type="text"
                    required
                    :rules="fillInputRules"
                    placeholder="First Name"
                    :disabled="detailsDisabled"
                  ></v-text-field>

                  <v-text-field
                    v-model="lastName"
                    outlined
                    filled
                    type="text"
                    required
                    :rules="fillInputRules"
                    placeholder="Last Name"
                    :disabled="detailsDisabled"
                  ></v-text-field>

                  <v-select
                    :items="isStaffOptions"
                    filled
                    v-model="isStaff"
                    label="Are You A Staff"
                    :disabled="detailsDisabled"
                  ></v-select>

                  <v-select
                    v-if="!isStaff"
                    :items="departments"
                    filled
                    v-model="department"
                    label="Department"
                    :disabled="detailsDisabled"
                  ></v-select>

                  <v-select
                    v-if="!isStaff"
                    :items="faculties"
                    filled
                    v-model="faculty"
                    label="Faculty"
                    :disabled="detailsDisabled"
                  ></v-select>

                  <v-text-field
                    v-model="matricNumber"
                    outlined
                    filled
                    type="text"
                    required
                    :placeholder="
                      isStaff ? 'Identification Number' : 'Matric Number'
                    "
                    :disabled="detailsDisabled"
                  ></v-text-field>

                  <v-menu
                    v-model="yearOfEntryPickerMenu"
                    :close-on-content-click="false"
                    transition="scale-transition"
                    offset-y
                    max-width="290px"
                    min-width="290px"
                  >
                    <template v-slot:activator="{ on, attrs }">
                      <v-text-field
                        outlined
                        filled
                        v-model="yearOfEntryFormatted"
                        label="Year Of Entry (read only text field)"
                        hint="YYYY format"
                        persistent-hint
                        readonly
                        @blur="yearOfEntry = getYearOfEntry(yearOfEntry)"
                        v-bind="attrs"
                        v-on="on"
                        :disabled="detailsDisabled"
                      ></v-text-field>
                    </template>
                    <v-date-picker
                      v-model="yearOfEntryFormatted"
                      no-title
                      @input="yearOfEntryPickerMenu = false"
                    ></v-date-picker>
                  </v-menu>

                  <v-menu
                    v-model="datePickerMenu"
                    :close-on-content-click="false"
                    transition="scale-transition"
                    offset-y
                    max-width="290px"
                    min-width="290px"
                  >
                    <template v-slot:activator="{ on, attrs }">
                      <v-text-field
                        outlined
                        filled
                        v-model="DOB"
                        label="Date (read only text field)"
                        hint="MM/DD/YYYY format"
                        persistent-hint
                        readonly
                        v-bind="attrs"
                        v-on="on"
                        :disabled="detailsDisabled"
                      ></v-text-field>
                    </template>
                    <v-date-picker
                      v-model="DOB"
                      no-title
                      @input="datePickerMenu = false"
                    ></v-date-picker>
                  </v-menu>

                  <v-alert
                    v-if="registrationErrorDetails"
                    dense
                    text
                    type="error"
                    >{{ registrationErrorDetails }}</v-alert
                  >
                </v-col>

                <v-col cols="12">
                  <v-btn
                    class="mr-4"
                    dark
                    @click="$router.push('/login')"
                    color="green"
                    tile
                    >Log In</v-btn
                  >
                  <v-btn
                    @click="registerUser()"
                    :disabled="detailsDisabled || !dataIsValid"
                    tile
                    >Register</v-btn
                  >
                </v-col>
              </v-row>
            </v-form>
          </v-col>
        </v-row>
      </v-container>
    </v-main>
  </v-app>
</template>

<script lang="ts">
import Vue from "vue";
import Axios from "axios";

export default Vue.extend({
  name: "Register",
  data: () => ({
    detailsDisabled: false,
    dataIsValid: false,
    datePickerMenu: false,
    yearOfEntryPickerMenu: false,

    departments: [],
    faculties: [],
    isStaffOptions: [true, false],

    registrationErrorDetails: "",
    yearOfEntryFormatted: new Date().toISOString().substr(0, 10),

    email: "",
    password: "",
    firstName: "",
    lastName: "",
    department: "",
    faculty: "",
    matricNumber: "",
    isStaff: false,
    DOB: new Date().toISOString().substr(0, 10),
    yearOfEntry: new Date().toISOString().substr(0, 10),

    emailRules: [
      (v: string) => !!v || "E-mail is required",
      (v: string) => /.+@.+\..+/.test(v) || "E-mail must be valid",
    ],
    fillInputRules: [(v: string) => !!v || "Field is required"],
  }),

  computed: {},

  methods: {
    registerUser() {
      this.detailsDisabled = true;

      console.log({
        email: this.email,
        password: this.password,
        firstName: this.firstName,
        lastName: this.lastName,
        department: this.department,
        faculty: this.faculty,
        matricNumber: this.matricNumber,
        isStaff: this.isStaff,
        dob: this.DOB,
        year: parseInt(this.yearOfEntry),
      });

      Axios.post(process.env.VUE_APP_BACKEND_SERVER + "/register", {
        email: this.email,
        password: this.password,
        firstName: this.firstName,
        lastName: this.lastName,
        department: this.department,
        faculty: this.faculty,
        matricNumber: this.matricNumber,
        isStaff: this.isStaff,
        dob: this.DOB,
        year: parseInt(this.yearOfEntry),
      })
        .then((Response) => {
          if (Response.status == 201) {
            this.$router.push("/login");
          }
        })
        .catch((Error) => {
          this.detailsDisabled = false;

          if (Error.response) {
            this.registrationErrorDetails = Error.response.data.error;
          }
        });
    },

    formatDate(date: string): string {
      if (!date) return "";

      const [year, month, day] = date.split("-");
      return `${month}/${day}/${year}`;
    },

    getYearOfEntry(date: string): string {
      if (!date) return "";

      const [year] = date.split("-");
      return year;
    },
  },

  async mounted() {
    try {
      this.departments = await Axios.get(
        process.env.VUE_APP_BACKEND_SERVER + "/helpers/departments"
      ).then((resp) => {
        if (resp.status == 200) {
          console.log(resp);
          return resp.data.data;
        }
      });
    } catch (error) {
      this.detailsDisabled = false;

      if (error.response) {
        this.registrationErrorDetails = error.response.error;
      }
    }

    try {
      this.faculties = await Axios.get(
        process.env.VUE_APP_BACKEND_SERVER + "/helpers/faculties"
      ).then((resp) => {
        if (resp.status == 200) {
          console.log(resp);
          return resp.data.data;
        }
      });
    } catch (error) {
      this.detailsDisabled = false;

      if (error.response) {
        this.registrationErrorDetails = error.response.error;
      }
    }
  },
});
</script>

<style>
</style>