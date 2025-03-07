<template>
<div style="padding: 20px;">
    <el-form v-if="anatObjects.length && !isDefacing">
        <p>
            If you'd like to deface all anatomical images, please select a defacing method and click <b>Run Deface</b> button. Defaced images will be reoriented via FSL's <i>reorient2std</i> function to ensure proper defacing.
        </p>
        <p>
            Otherwise, you can skip this page.
        </p>

        <el-form-item>
            <b>Defacing Method </b>
            <br>
            <el-select v-model="ezbids.defacingMethod" placeholder="Select a defacing method" style="width: 300px;" @change="changeMethod">
                <el-option value="" label="Don't Deface (use original)"/>
                <el-option value="quickshear" label="Quickshear (recommended)"/>
                <el-option value="pydeface" label="pyDeface (more common but takes much longer time)"/>
            </el-select>
        </el-form-item>
        <!--sub options-->
        <p v-if="ezbids.defacingMethod == 'quickshear'">
            <small>* Use ROBEX and QuickShear Average processing time. 1min per image</small>
        </p>
        <p v-if="ezbids.defacingMethod == 'pydeface'">
            <small>* pydeface uses fsl to align facial mask template. 5min per image</small>
        </p>
    </el-form>

    <el-form>
        <el-form-item>
            <el-button v-if="!isDefacing && ezbids.defacingMethod && !session.deface_finish_date" @click="runDeface" type="success">Run Deface</el-button>
            <el-button @click="cancel" v-if="isDefacing" type="warning">Cancel Defacing</el-button>
            <el-button @click="reset" v-if="session.deface_begin_date && session.deface_finish_date">Reset Deface</el-button>
        </el-form-item>
    </el-form>

    <br>
    <el-alert v-if="anatObjects.length == 0" type="warning">No anatomy files to deface. Please skip this step.</el-alert>
    <div v-if="anatObjects.length && ezbids.defacingMethod">
        <div v-if="session.status == 'deface' || session.status == 'defacing'">
            <h3>Running <b>{{ezbids.defacingMethod}}</b> ...</h3>
            <pre class="status">{{session.status_msg}}</pre>
        </div>
        <div v-if="session.deface_finish_date">
            <el-alert type="success" show-icon>
                Defacing completed! Please check the defacing results and proceed to the next page.
            </el-alert>
        </div>
        <div v-if="session.status == 'failed'">
            Failed!
            <pre class="status">{{session.status_msg}}</pre>
        </div>
    </div>

    <table v-if="session.deface_begin_date" class="table">
        <thead>
            <tr>
                <th></th>
                <th>Original</th>
                <th>Defaced</th>
            </tr>
        </thead>
        <tr v-for="anat in anatObjects" :key="anat.idx">
            <td>
                <div style="margin-bottom: 0; font-size: 85%; line-height: 200%;">
                    <span><small>sub</small> {{anat._entities.subject}} </span>
                    <span v-if="anat._entities.session">/ <small>ses</small> {{anat._entities.session}} </span>
                </div>
                <el-tag type="info" size="mini">#{{anat.series_idx}}</el-tag>
                &nbsp;
                <datatype :type="anat._type" :series_idx="anat.series_idx" :entities="anat.entities"/>
            </td>
            <td width="40%" style="position: relative">
                <el-radio v-model="anat.defaceSelection" label="original">Use Original</el-radio>
                <div v-for="(item, itemIdx) in anat.items" :key="itemIdx">
                    <div v-if="item.pngPaths">
                        <a :href="getURL(item.pngPaths[0])">
                            <img style="width: 100%" :src="getURL(item.pngPaths[0])"/>
                        </a>
                        <el-button type="info" @click="$emit('niivue', item.path)" style="position: absolute; top: 50px; left: 5px" size="small">
                            <font-awesome-icon :icon="['fas', 'eye']"/>
                            NiiVue
                        </el-button>
                    </div>
                </div>
            </td>
            <td width="40%" style="position: relative">
                <el-radio v-model="anat.defaceSelection" label="defaced">Use Defaced (when finish defacing)</el-radio>
                <div v-if="anat.defaced">
                    <a :href="getURL(getDefacedURL(anat)+'.png')" v-if="anat.defaced">
                        <img style="width: 100%" :src="getURL(getDefacedURL(anat)+'.png')+'?nocache='+Date.now()"/>
                    </a>
                    <el-button type="info" @click="$emit('niivue', getDefacedURL(anat))" style="position: absolute; top: 50px; left: 5px;" size="small">
                        <font-awesome-icon :icon="['fas', 'eye']"/>
                        NiiVue
                    </el-button>
                </div>
                <p v-if="session.status == 'defacing' && !anat.defaced" class="missingThumb">
                <small>
                    Defacing 
                    <font-awesome-icon icon="spinner" pulse/>
                </small>
                </p>
                <p v-if="anat.defaceFailed" class="missingThumb fail"><small>Defacing Failed</small></p>
            </td>
        </tr>
    </table>

</div>
</template>

<script lang="ts">

import { mapState, mapGetters, } from 'vuex'
import { defineComponent } from 'vue'
import datatype from './components/datatype.vue'
import niivue from './components/niivue.vue'

import { IObject } from './store'

import { ElNotification } from 'element-plus'

export default defineComponent({
    components: {
        datatype,
        niivue,
    },

    /*
    data() {
        return {
        }
    },
    */

    mounted() {
        //initialize all anat to use defaced image by default
        this.anatObjects.forEach((o:IObject)=>{
            if(!o.defaceSelection) o.defaceSelection = "defaced";
        });
    },

    computed: {
        ...mapState(['ezbids', 'config', 'session', 'bidsSchema']),
        ...mapGetters(['getBIDSEntities', 'getURL']),

        isDefacing() {
            if(!this.$store.state.session) return false;
            return ["deface", "defacing"].includes(this.$store.state.session.status);
        },

        anatObjects() {
            return this.$store.state.ezbids.objects.filter((o:IObject)=>o._type.startsWith('anat') && !o._exclude)
        }
    },

    methods: {
        changeMethod() {
            if(this.ezbids.defacingMethod) {
                this.anatObjects.forEach((o:IObject)=>{
                    o.defaceSelection = "defaced";
                });
            } else {
                this.anatObjects.forEach((o:IObject)=>{
                    o.defaceSelection = "original";
                });
            }
        },

        getDefacedURL(anat: IObject) {
            //find the image path first
            let item = anat.items.find(i=>i.path.endsWith(".nii.gz"));
            if(!item) return null;

            //guess the image path
            return item.path+".defaced.nii.gz";
        },

        cancel() {
            fetch(this.config.apihost+'/session/'+this.session._id+'/canceldeface', {
                method: "POST",
                headers: {'Content-Type': 'application/json; charset=UTF-8'},
            }).then(res=>res.text()).then(status=>{
                if(status != "ok") {
                    ElNotification({ title: 'Failed', message: 'Failed to cancel defacing'});
                } else {
                    ElNotification({ title: 'Success', message: 'Requested to cancel defacing..'});
                }
                this.$store.dispatch("loadSession", this.session._id);
            });
        },

        reset() {
            fetch(this.config.apihost+'/session/'+this.session._id+'/resetdeface', {
                method: "POST",
                headers: {'Content-Type': 'application/json; charset=UTF-8'},
            }).then(res=>res.text()).then(status=>{
                if(status != "ok") {
                    ElNotification({ title: 'Failed', message: 'Failed to reset defacing'});
                }
                this.anatObjects.forEach((anat: IObject)=>{
                    delete anat.defaced;
                    delete anat.defaceFailed;
                    anat.defaceSelection = "defaced";
                });
                this.$store.dispatch("loadSession", this.session._id);
            });
        },

        runDeface() {
            const list = this.anatObjects.map((o:IObject)=>{
                return {idx: o.idx, path: o.items.find(i=>i.path?.endsWith(".nii.gz"))?.path};
            });

            //reset current status for all stats (in case it's ran previously)
            this.anatObjects.forEach((o:IObject)=>{
                delete o.defaced;
            });

            fetch(this.config.apihost+'/session/'+this.session._id+'/deface', {
                method: "POST",
                headers: {'Content-Type': 'application/json; charset=UTF-8'},
                body: JSON.stringify({
                    list,
                    method: this.ezbids.defacingMethod,
                }),
            }).then(res=>res.text()).then(status=>{
                if(status != "ok") {
                    ElNotification({ title: 'Failed', message: 'Failed to submit deface request'});
                }
                this.$store.dispatch("loadSession", this.session._id);
                //this.$root.pollSession();
            });
        },

        isValid(cb: (v?: string)=>void) {
            if(!this.ezbids.defacingMethod) return cb();
            if(!this.session.deface_begin_date) {
                return cb("Please run deface");
            }
            if(this.session.deface_begin_date && this.session.status == "failed") {
                //let's assume it's the defacing that failed
                let err = undefined;
                this.anatObjects.forEach((o:IObject)=>{
                    if(o.defaceSelection == "defaced" && !o.defaced) err = "Please set to use original image for deface-failed images";
                });
                return cb(err);
            }
            if(!this.session.deface_finish_date) {
                return cb("Please wait for defacing to finish");
            }
            cb();
        },

    },
});
</script>
<style lang="scss" scoped>
.deface {
    position: fixed;
    top: 0;
    bottom: 60px;
    left: 210px;
    right: 0;
    overflow: auto;
}
.table {
}
.table td {
    border-top: 1px solid #eee;
    padding-top: 5px;
}
.table th {
    text-align: left;
    padding: 5px 0;
}
.table td {
    vertical-align: top;
}
.missingThumb {
    background-color: #f0f0f0;
    padding: 10px 20px;
    box-sizing: border-box;
    margin: 0;
}
.missingThumb.fail {
    background-color: #c44;
    color: white;
}
.el-form-item {
    margin-bottom: 0;
}
pre.status {
    background-color: #666;
    color: white;
    height: 125px;
    overflow: auto;
    padding: 10px;
    margin-bottom: 5px;
    border-radius: 5px;
}
</style>

