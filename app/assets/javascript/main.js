import * as THREE from 'three';
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js';
import { MTLLoader } from 'three/addons/loaders/MTLLoader.js';
//import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

let cameraStates = [
    [[3.890794575489123, 0.9752466284680337, 3.406702477655009], [-0.06501676300811605, 0.014735025041483576, 0.0009593408193955247], 1.0],
    [[2.4221213024953085, 0.44182968124302335, 1.5086600466763138], [-0.09449775865214692, 0.17447782373791565, 0.01645175529882499], 0.1],
    [[2.16961166187931, 0.4052103230024016, 1.18371895845364], [-0.04720442442221636, 0.22739843858771805, 0.01064944896585632], 0.0],
];

function getCameraState(index) {
    if (index == 2) {
        let a = structuredClone(cameraStates[2]);
        a[0][0] = cameraStates[2][0][0] + travelDistance;
        return a
    } else {
        return cameraStates[index];
    }
}

globalThis.setTravelDistance = (v) => { travelDistance = v; setCameraState(2); water.position.x = waterOriginX + travelDistance; };

let disableStartLerp = typeof (_disableStartLerp) == "boolean" && _disableStartLerp == true;

let storedCameraState = JSON.parse(localStorage.getItem("lastCameraState")) || cameraStates[0];

let targetCameraState = getCameraState(typeof (_activeCameraStateIndex) == "number" && parseInt(_activeCameraStateIndex) || 0);

if (disableStartLerp) {
    localStorage.setItem("lastCameraState", JSON.stringify(targetCameraState));
    storedCameraState = targetCameraState;
}
let activeCameraState = structuredClone(storedCameraState);

if (storedCameraState != targetCameraState) {
    localStorage.setItem("lastCameraState", JSON.stringify(targetCameraState));
    storedCameraState = targetCameraState;
}

const loader = new THREE.TextureLoader();
const texture = await loader.loadAsync('3d/water2.JPG');
texture.wrapS = THREE.RepeatWrapping;
texture.wrapT = THREE.RepeatWrapping;

// texture.magFilter = THREE.NearestFilter;
// texture.minFilter = THREE.NearestFilter;

let width = document.documentElement.clientWidth * window.devicePixelRatio;
let height = document.documentElement.clientHeight * window.devicePixelRatio;

// init

// use higher clipping plane if _showOceanSlice is defined and set to true
let showOceanSlice = typeof (_showOceanSlice) != "undefined" && _showOceanSlice == true;
let nearClipping = showOceanSlice ? 1.3 : 0.1;

const camera = new THREE.PerspectiveCamera(70, width / height, nearClipping, 100);
const scene = new THREE.Scene();

// add fog to show perspective
const color = 0;
const near = 0.1;
const far = 10;
scene.fog = new THREE.Fog(color, near, far);

const renderer = new THREE.WebGLRenderer({ antialias: true });
//const controls = new OrbitControls(camera, renderer.domElement);
let waterShader = new THREE.ShaderMaterial({
    uniforms: {
        buffer: { value: texture },
        time: { type: 'float', value: 0.0 },
    },
    vertexShader: vertexShader(),
    fragmentShader: fragmentShader()
});

function getCameraOffset(aspect) {
    return (0.9639917695473 * aspect - 1.9753086419753) * activeCameraState[2];
}

renderer.setSize(width, height);
renderer.setClearColor(new THREE.Color(0x3DABFF), 0)

function vertexShader() {
    return `
    uniform float time;
    varying vec2 vUv;
    varying float h;

    void main(){
        vUv=position.xz*0.1+.5;
        vec3 c = position;
        c.y += sin(time/1200.0+position.z+position.x) * 0.04;
        h=c.y;

        vec4 modelViewPosition = modelViewMatrix * vec4(c, 1.0);
        gl_Position = projectionMatrix * modelViewPosition;
    }
  `
}
function fragmentShader() {
    return `
    precision highp float;

    uniform sampler2D buffer;
    varying vec2 vUv;
    varying float h;
    uniform float time;

    void main(){
        float value = (h)*1.3;
        vec2 movedUv = vUv;
        movedUv.y += sin(time/1000.0)/100.0;
        movedUv.x += sin(time/1000.0)/100.0;
        vec4 texel=texture2D(buffer,movedUv);
        texel.rgb += vec3(value,value,value);
        gl_FragColor=texel;
    }
    `
}
const mtlLoader = new MTLLoader().setPath('3d/');
const objLoader = new OBJLoader().setPath('3d/');

async function loadModel(name, material) {
    const materials = await mtlLoader.loadAsync(name + '.mtl');
    materials.preload();
    if (material != undefined && material != null) {
        materials.materials.Material = material;
    }
    // add transparency for bush and ship material.
    // ik this is hardcoded and all but im in a hurry to get this finished ok
    if (materials.materials.Bush != null) {
        materials.materials.Bush.transparent = true;
        materials.materials.Ship.transparent = true;
    }
    for (let m of Object.keys(materials.materials)) {
        if (materials.materials[m].map == undefined) { continue }
        materials.materials[m].map.magFilter = THREE.NearestFilter;
        materials.materials[m].map.minFilter = THREE.NearestFilter;
    }
    objLoader.setMaterials(materials);

    return await objLoader.loadAsync(name + '.obj')
}

let island = await loadModel("island");
let ship;
for (let child of island.children) {
    if (child.name == "Ship") {
        ship = child;
    }
}
ship.position.x = travelDistance;

globalThis.setShipDirection = function (scale) {
    ship.material.map.repeat.x = scale;
}
if (shipStatus != 0) {
    setShipDirection(-1);
}

scene.add(island);
let water = await loadModel("water", waterShader);

water.position.y = 0.125;
let waterOriginX = 5.5;
water.position.x = waterOriginX + travelDistance;
water.position.z = -10.5;
scene.add(water);

globalThis.camera = camera;

// lights :>
const ambientLight = new THREE.AmbientLight(0xffffff, 3);
scene.add(ambientLight);
//const hemiLight = new THREE.HemisphereLight(0x0000ff, 0x00ff00, 0.6);
//scene.add(hemiLight);

renderer.setAnimationLoop(animate);
document.body.appendChild(renderer.domElement);

function updateCameraPos() {
    camera.position.set(activeCameraState[0][0] + getCameraOffset(width / height), activeCameraState[0][1], activeCameraState[0][2]);

    camera.rotation.x = activeCameraState[1][0];
    camera.rotation.y = activeCameraState[1][1];
    camera.rotation.z = activeCameraState[1][2];
}

// set up default camera state
updateCameraPos();

function lerp(a, b, t) {
    return a + (b - a) * t;
}
function lerpCameraState(a, b, t) {
    for (let tci = 0; tci < 2; tci++) {
        for (let ci = 0; ci < 3; ci++) {
            a[tci][ci] = lerp(a[tci][ci], b[tci][ci], t);
        }
    }
    a[2] = lerp(a[2], b[2], t);
}

function setCameraState(index) {
    targetCameraState = getCameraState(index);
    localStorage.setItem("lastCameraState", JSON.stringify(targetCameraState));
}
globalThis.setCameraState = setCameraState;

let previousTime = 0.0;
function animate(time) {
    waterShader.uniforms["time"].value = time;
    let deltaTime = time - previousTime;
    previousTime = time;

    lerpCameraState(activeCameraState, targetCameraState, Math.min(deltaTime / 1000.0, 1.0 / 60.0) * 5.0);
    updateCameraPos();
    let relPosition = water.position;
    // PI / 16 is subtracted to make it a bit delayed compared to the water
    // to give an effect of having mass
    ship.position.y = Math.sin(time / 1200.0 + relPosition.z + relPosition.x - Math.PI / 16 - travelDistance) * 0.04;

    ship.position.x = lerp(ship.position.x, travelDistance, Math.min(deltaTime / 1000.0, 1.0 / 60.0) * 2.0);

    //controls.update();
    renderer.render(scene, camera);
}

window.addEventListener("resize", () => {
    width = document.documentElement.clientWidth * window.devicePixelRatio;
    height = document.documentElement.clientHeight * window.devicePixelRatio;

    camera.width = width;
    camera.height = height;
    camera.aspect = width / height
    camera.updateProjectionMatrix();

    renderer.setSize(width, height);
});

document.getElementById("loading").remove();
let v = document.getElementById("varyingContents");
if (v) {
    v.classList.remove("hidden");
}