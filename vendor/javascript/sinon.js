// sinon@21.0.0 downloaded from https://ga.jspm.io/npm:sinon@21.0.0/pkg/sinon-esm.js

/* Sinon.JS 21.0.0, 2025-06-13, @license BSD-3 */let e;(function(){function e(t,n,r){function o(s,a){if(!n[s]){if(!t[s]){var c="function"==typeof require&&require;if(!a&&c)return c(s,!0);if(i)return i(s,!0);var l=new Error("Cannot find module '"+s+"'");throw l.code="MODULE_NOT_FOUND",l}var u=n[s]={exports:{}};t[s][0].call(u.exports,(function(e){var n=t[s][1][e];return o(n||e)}),u,u.exports,e,t,n,r)}return n[s].exports}for(var i="function"==typeof require&&require,s=0;s<r.length;s++)o(r[s]);return o}return e})()({1:[function(e,t,n){const r=e("./sinon/behavior");const o=e("./sinon/create-sandbox");const i=e("./sinon/util/core/extend");const s=e("./sinon/util/fake-timers");const a=e("./sinon/sandbox");const c=e("./sinon/stub");const l=e("./sinon/promise");
/**
 * @returns {object} a configured sandbox
 */t.exports=function(){const t={createSandbox:o,match:e("@sinonjs/samsam").createMatcher,restoreObject:e("./sinon/restore-object"),expectation:e("./sinon/mock-expectation"),timers:s.timers,addBehavior:function(e,t){r.addBehavior(c,e,t)},promise:l};const n=new a;return i(n,t)}},{"./sinon/behavior":5,"./sinon/create-sandbox":8,"./sinon/mock-expectation":12,"./sinon/promise":14,"./sinon/restore-object":19,"./sinon/sandbox":20,"./sinon/stub":23,"./sinon/util/core/extend":26,"./sinon/util/fake-timers":40,"@sinonjs/samsam":87}],2:[function(t,n,r){e=t("./sinon")},{"./sinon":3}],3:[function(e,t,n){const r=e("./create-sinon-api");t.exports=r()},{"./create-sinon-api":1}],4:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("@sinonjs/commons").calledInOrder;const i=e("@sinonjs/samsam").createMatcher;const s=e("@sinonjs/commons").orderByFirstCall;const a=e("./util/core/times-in-words");const c=e("util").inspect;const l=e("@sinonjs/commons").prototypes.string.slice;const u=e("@sinonjs/commons").global;const f=r.slice;const p=r.concat;const h=r.forEach;const d=r.join;const m=r.splice;function y(e,t){for(const n of Object.keys(t)){const r=e[n];r!==null&&typeof r!=="undefined"||(e[n]=t[n])}}
/**
 * @typedef {object} CreateAssertOptions
 * @global
 *
 * @property {boolean} [shouldLimitAssertionLogs] default is false
 * @property {number}  [assertionLogLimit] default is 10K
 */
/**
 * Create an assertion object that exposes several methods to invoke
 *
 * @param {CreateAssertOptions}  [opts] options bag
 * @returns {object} object with multiple assertion methods
 */function g(e){const t=e||{};y(t,{shouldLimitAssertionLogs:false,assertionLogLimit:1e4});const n={fail:function(e){let n=e;t.shouldLimitAssertionLogs&&(n=e.substring(0,t.assertionLogLimit));const r=new Error(n);r.name="AssertError";throw r},pass:function(){},callOrder:function(){r.apply(null,arguments);let e="";let t="";if(o(arguments))n.pass("callOrder");else{try{e=d(arguments,", ");const n=f(arguments);let r=n.length;while(r)n[--r].called||m(n,r,1);t=d(s(n),", ")}catch(e){}v(this,`expected ${e} to be called in order but were called as ${t}`)}},callCount:function(e,t){r(e);let o;if(typeof t!=="number"){o=`expected ${c(t)} to be a number but was of type `+typeof t;v(this,o)}else if(e.callCount!==t){o=`expected %n to be called ${a(t)} but was called %c%C`;v(this,e.printf(o))}else n.pass("callCount")},expose:function(e,t){if(!e)throw new TypeError("target is null or undefined");const n=t||{};const r=typeof n.prefix==="undefined"?"assert":n.prefix;const o=typeof n.includeFail==="undefined"||Boolean(n.includeFail);const i=this;h(Object.keys(i),(function(t){t==="expose"||!o&&/^(fail)/.test(t)||(e[w(r,t)]=i[t])}));return e},match:function(e,t){const r=i(t);if(r.test(e))n.pass("match");else{const n=["expected value to match",`    expected = ${c(t)}`,`    actual = ${c(e)}`];v(this,d(n,"\n"))}}};function r(){const e=f(arguments);h(e,(function(e){e||n.fail("fake is not a spy");if(e.proxy&&e.proxy.isSinonProxy)r(e.proxy);else{typeof e!=="function"&&n.fail(`${e} is not a function`);typeof e.getCall!=="function"&&n.fail(`${e} is not stubbed`)}}))}function g(e,t){switch(e){case"notCalled":case"called":case"calledOnce":case"calledTwice":case"calledThrice":t.length!==0&&n.fail(`${e} takes 1 argument but was called with ${t.length+1} arguments`);break;default:break}}function v(e,t){const r=e||u;const o=r.fail||n.fail;o.call(r,t)}function b(e,t,o){let i=o;let s=t;if(arguments.length===2){i=t;s=e}n[e]=function(t){r(t);const o=f(arguments,1);let a=false;g(e,o);a=typeof s==="function"?!s(t):typeof t[s]==="function"?!t[s].apply(t,o):!t[s];a?v(this,(t.printf||t.proxy.printf).apply(t,p([i],o))):n.pass(e)}}function w(e,t){return!e||/^fail/.test(t)?t:e+l(t,0,1).toUpperCase()+l(t,1)}b("called","expected %n to have been called at least once but was never called");b("notCalled",(function(e){return!e.called}),"expected %n to not have been called but was called %c%C");b("calledOnce","expected %n to be called once but was called %c%C");b("calledTwice","expected %n to be called twice but was called %c%C");b("calledThrice","expected %n to be called thrice but was called %c%C");b("calledOn","expected %n to be called with %1 as this but was called with %t");b("alwaysCalledOn","expected %n to always be called with %1 as this but was called with %t");b("calledWithNew","expected %n to be called with new");b("alwaysCalledWithNew","expected %n to always be called with new");b("calledWith","expected %n to be called with arguments %D");b("calledWithMatch","expected %n to be called with match %D");b("alwaysCalledWith","expected %n to always be called with arguments %D");b("alwaysCalledWithMatch","expected %n to always be called with match %D");b("calledWithExactly","expected %n to be called with exact arguments %D");b("calledOnceWithExactly","expected %n to be called once and with exact arguments %D");b("calledOnceWithMatch","expected %n to be called once and with match %D");b("alwaysCalledWithExactly","expected %n to always be called with exact arguments %D");b("neverCalledWith","expected %n to never be called with arguments %*%C");b("neverCalledWithMatch","expected %n to never be called with match %*%C");b("threw","%n did not throw exception%C");b("alwaysThrew","%n did not always throw exception%C");return n}t.exports=g();t.exports.createAssertObject=g},{"./util/core/times-in-words":36,"@sinonjs/commons":47,"@sinonjs/samsam":87,util:91}],5:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./util/core/extend");const i=e("@sinonjs/commons").functionName;const s=e("./util/core/next-tick");const a=e("@sinonjs/commons").valueToString;const c=e("./util/core/export-async-behaviors");const l=r.concat;const u=r.join;const f=r.reverse;const p=r.slice;const h=-1;const d=-2;function m(e,t){const n=e.callArgAt;if(n>=0)return t[n];let r;n===h&&(r=t);n===d&&(r=f(p(t)));const o=e.callArgProp;for(let e=0,t=r.length;e<t;++e){if(!o&&typeof r[e]==="function")return r[e];if(o&&r[e]&&typeof r[e][o]==="function")return r[e][o]}return null}function y(e,t,n){if(e.callArgAt<0){let t;t=e.callArgProp?`${i(e.stub)} expected to yield to '${a(e.callArgProp)}', but no object with such a property was passed.`:`${i(e.stub)} expected to yield, but no callback was passed.`;n.length>0&&(t+=` Received [${u(n,", ")}]`);return t}return`argument at index ${e.callArgAt} is not a function: ${t}`}function g(e,t,n){const r=e.replace(/sArg/,"ArgAt");const o=t[r];if(o>=n.length)throw new TypeError(`${e} failed: ${o+1} arguments required but only ${n.length} present`)}function v(e,t){if(typeof e.callArgAt==="number"){g("callsArg",e,t);const n=m(e,t);if(typeof n!=="function")throw new TypeError(y(e,n,t));if(!e.callbackAsync)return n.apply(e.callbackContext,e.callbackArguments);s((function(){n.apply(e.callbackContext,e.callbackArguments)}))}}const b={create:function(e){const t=o({},b);delete t.create;delete t.addBehavior;delete t.createBehavior;t.stub=e;e.defaultBehavior&&e.defaultBehavior.promiseLibrary&&(t.promiseLibrary=e.defaultBehavior.promiseLibrary);return t},isPresent:function(){return typeof this.callArgAt==="number"||this.exception||this.exceptionCreator||typeof this.returnArgAt==="number"||this.returnThis||typeof this.resolveArgAt==="number"||this.resolveThis||typeof this.throwArgAt==="number"||this.fakeFn||this.returnValueDefined},invoke:function(e,t){const n=v(this,t);if(this.exception)throw this.exception;if(this.exceptionCreator){this.exception=this.exceptionCreator();this.exceptionCreator=void 0;throw this.exception}if(typeof this.returnArgAt==="number"){g("returnsArg",this,t);return t[this.returnArgAt]}if(this.returnThis)return e;if(typeof this.throwArgAt==="number"){g("throwsArg",this,t);throw t[this.throwArgAt]}if(this.fakeFn)return this.fakeFn.apply(e,t);if(typeof this.resolveArgAt==="number"){g("resolvesArg",this,t);return(this.promiseLibrary||Promise).resolve(t[this.resolveArgAt])}if(this.resolveThis)return(this.promiseLibrary||Promise).resolve(e);if(this.resolve)return(this.promiseLibrary||Promise).resolve(this.returnValue);if(this.reject)return(this.promiseLibrary||Promise).reject(this.returnValue);if(this.callsThrough){const n=this.effectiveWrappedMethod();return n.apply(e,t)}if(this.callsThroughWithNew){const e=this.effectiveWrappedMethod();const n=p(t);const r=e.bind.apply(e,l([null],n));return new r}return typeof this.returnValue!=="undefined"?this.returnValue:typeof this.callArgAt==="number"?n:this.returnValue},effectiveWrappedMethod:function(){for(let e=this.stub;e;e=e.parent)if(e.wrappedMethod)return e.wrappedMethod;throw new Error("Unable to find wrapped method")},onCall:function(e){return this.stub.onCall(e)},onFirstCall:function(){return this.stub.onFirstCall()},onSecondCall:function(){return this.stub.onSecondCall()},onThirdCall:function(){return this.stub.onThirdCall()},withArgs:function(){throw new Error('Defining a stub by invoking "stub.onCall(...).withArgs(...)" is not supported. Use "stub.withArgs(...).onCall(...)" to define sequential behavior for calls with certain arguments.')}};function w(e){return function(){this.defaultBehavior=this.defaultBehavior||b.create(this);this.defaultBehavior[e].apply(this.defaultBehavior,arguments);return this}}function x(e,t,n){b[t]=function(){n.apply(this,l([this],p(arguments)));return this.stub||this};e[t]=w(t)}b.addBehavior=x;b.createBehavior=w;const j=c(b);t.exports=o.nonEnum({},b,j)},{"./util/core/export-async-behaviors":25,"./util/core/extend":26,"./util/core/next-tick":34,"@sinonjs/commons":47}],6:[function(e,t,n){const r=e("./util/core/walk");const o=e("./util/core/get-property-descriptor");const i=e("@sinonjs/commons").prototypes.object.hasOwnProperty;const s=e("@sinonjs/commons").prototypes.array.push;function a(e,t,n,r){typeof o(r,n).value==="function"&&i(t,n)&&s(e,t[n])}function c(e){const t=[];r(e,a.bind(null,t,e));return t}t.exports=c},{"./util/core/get-property-descriptor":29,"./util/core/walk":38,"@sinonjs/commons":47}],7:[function(e,t,n){t.exports=class Colorizer{constructor(t=e("supports-color")){this.supportsColor=t}colorize(e,t){return this.supportsColor.stdout===false?e:`[${t}m${e}[0m`}red(e){return this.colorize(e,31)}green(e){return this.colorize(e,32)}cyan(e){return this.colorize(e,96)}white(e){return this.colorize(e,39)}bold(e){return this.colorize(e,1)}}},{"supports-color":94}],8:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./sandbox");const i=r.forEach;const s=r.push;function a(e){const t=new o({assertOptions:e.assertOptions});e.useFakeTimers&&(typeof e.useFakeTimers==="object"?t.useFakeTimers(e.useFakeTimers):t.useFakeTimers());return t}function c(e,t,n,r){if(r)if(t.injectInto&&!(n in t.injectInto)){t.injectInto[n]=r;s(e.injectedKeys,n)}else s(e.args,r)}
/**
 * Options to customize a sandbox
 *
 * The sandbox's methods can be injected into another object for
 * convenience. The `injectInto` configuration option can name an
 * object to add properties to.
 *
 * @typedef {object} SandboxConfig
 * @property {string[]} properties The properties of the API to expose on the sandbox. Examples: ['spy', 'fake', 'restore']
 * @property {object} injectInto an object in which to inject properties from the sandbox (a facade). This is mostly an integration feature (sinon-test being one).
 * @property {boolean} useFakeTimers  whether timers are faked by default
 * @property {object} [assertOptions] see CreateAssertOptions in ./assert
 *
 * This type def is really suffering from JSDoc not having standardized
 * how to reference types defined in other modules :(
 */
/**
 * A configured sinon sandbox (private type)
 *
 * @typedef {object} ConfiguredSinonSandboxType
 * @private
 * @augments Sandbox
 * @property {string[]} injectedKeys the keys that have been injected (from config.injectInto)
 * @property {*[]} args the arguments for the sandbox
 */
/**
 * Create a sandbox
 *
 * As of Sinon 5 the `sinon` instance itself is a Sandbox, so you
 * hardly ever need to create additional instances for the sake of testing
 *
 * @param config {SandboxConfig}
 * @returns {Sandbox}
 */function l(e){if(!e)return new o;const t=a(e);t.args=t.args||[];t.injectedKeys=[];t.injectInto=e.injectInto;const n=t.inject({});e.properties?i(e.properties,(function(r){const o=n[r]||r==="sandbox"&&t;c(t,e,r,o)})):c(t,e,"sandbox");return t}t.exports=l},{"./sandbox":20,"@sinonjs/commons":47}],9:[function(e,t,n){const r=e("./stub");const o=e("./util/core/sinon-type");const i=e("@sinonjs/commons").prototypes.array.forEach;function s(e){return o.get(e)==="stub"}t.exports=function(e,t){if(typeof e!=="function")throw new TypeError("The constructor should be a function.");const n=Object.create(e.prototype);o.set(n,"stub-instance");const a=r(n);i(Object.keys(t||{}),(function(e){if(!(e in a))throw new Error(`Cannot stub ${e}. Property does not exist!`);{const n=t[e];s(n)?a[e]=n:a[e].returns(n)}}));return a}},{"./stub":23,"./util/core/sinon-type":35,"@sinonjs/commons":47}],10:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./util/core/is-property-configurable");const i=e("./util/core/export-async-behaviors");const s=e("./util/core/extend");const a=r.slice;const c=-1;const l=-2;function u(e,t,n){typeof t==="function"?e.exceptionCreator=t:typeof t==="string"?e.exceptionCreator=function(){const e=new Error(n||`Sinon-provided ${t}`);e.name=t;return e}:t?e.exception=t:e.exceptionCreator=function(){return new Error("Error")}}const f={callsFake:function(e,t){e.fakeFn=t;e.exception=void 0;e.exceptionCreator=void 0;e.callsThrough=false},callsArg:function(e,t){if(typeof t!=="number")throw new TypeError("argument index is not number");e.callArgAt=t;e.callbackArguments=[];e.callbackContext=void 0;e.callArgProp=void 0;e.callbackAsync=false;e.callsThrough=false},callsArgOn:function(e,t,n){if(typeof t!=="number")throw new TypeError("argument index is not number");e.callArgAt=t;e.callbackArguments=[];e.callbackContext=n;e.callArgProp=void 0;e.callbackAsync=false;e.callsThrough=false},callsArgWith:function(e,t){if(typeof t!=="number")throw new TypeError("argument index is not number");e.callArgAt=t;e.callbackArguments=a(arguments,2);e.callbackContext=void 0;e.callArgProp=void 0;e.callbackAsync=false;e.callsThrough=false},callsArgOnWith:function(e,t,n){if(typeof t!=="number")throw new TypeError("argument index is not number");e.callArgAt=t;e.callbackArguments=a(arguments,3);e.callbackContext=n;e.callArgProp=void 0;e.callbackAsync=false;e.callsThrough=false},yields:function(e){e.callArgAt=c;e.callbackArguments=a(arguments,1);e.callbackContext=void 0;e.callArgProp=void 0;e.callbackAsync=false;e.fakeFn=void 0;e.callsThrough=false},yieldsRight:function(e){e.callArgAt=l;e.callbackArguments=a(arguments,1);e.callbackContext=void 0;e.callArgProp=void 0;e.callbackAsync=false;e.callsThrough=false;e.fakeFn=void 0},yieldsOn:function(e,t){e.callArgAt=c;e.callbackArguments=a(arguments,2);e.callbackContext=t;e.callArgProp=void 0;e.callbackAsync=false;e.callsThrough=false;e.fakeFn=void 0},yieldsTo:function(e,t){e.callArgAt=c;e.callbackArguments=a(arguments,2);e.callbackContext=void 0;e.callArgProp=t;e.callbackAsync=false;e.callsThrough=false;e.fakeFn=void 0},yieldsToOn:function(e,t,n){e.callArgAt=c;e.callbackArguments=a(arguments,3);e.callbackContext=n;e.callArgProp=t;e.callbackAsync=false;e.fakeFn=void 0},throws:u,throwsException:u,returns:function(e,t){e.callsThrough=false;e.returnValue=t;e.resolve=false;e.reject=false;e.returnValueDefined=true;e.exception=void 0;e.exceptionCreator=void 0;e.fakeFn=void 0},returnsArg:function(e,t){if(typeof t!=="number")throw new TypeError("argument index is not number");e.callsThrough=false;e.returnArgAt=t},throwsArg:function(e,t){if(typeof t!=="number")throw new TypeError("argument index is not number");e.callsThrough=false;e.throwArgAt=t},returnsThis:function(e){e.returnThis=true;e.callsThrough=false},resolves:function(e,t){e.returnValue=t;e.resolve=true;e.resolveThis=false;e.reject=false;e.returnValueDefined=true;e.exception=void 0;e.exceptionCreator=void 0;e.fakeFn=void 0;e.callsThrough=false},resolvesArg:function(e,t){if(typeof t!=="number")throw new TypeError("argument index is not number");e.resolveArgAt=t;e.returnValue=void 0;e.resolve=true;e.resolveThis=false;e.reject=false;e.returnValueDefined=false;e.exception=void 0;e.exceptionCreator=void 0;e.fakeFn=void 0;e.callsThrough=false},rejects:function(e,t,n){let r;if(typeof t==="string"){r=new Error(n||"");r.name=t}else r=t||new Error("Error");e.returnValue=r;e.resolve=false;e.resolveThis=false;e.reject=true;e.returnValueDefined=true;e.exception=void 0;e.exceptionCreator=void 0;e.fakeFn=void 0;e.callsThrough=false;return e},resolvesThis:function(e){e.returnValue=void 0;e.resolve=false;e.resolveThis=true;e.reject=false;e.returnValueDefined=false;e.exception=void 0;e.exceptionCreator=void 0;e.fakeFn=void 0;e.callsThrough=false},callThrough:function(e){e.callsThrough=true},callThroughWithNew:function(e){e.callsThroughWithNew=true},get:function(e,t){const n=e.stub||e;Object.defineProperty(n.rootObj,n.propName,{get:t,configurable:o(n.rootObj,n.propName)});return e},set:function(e,t){const n=e.stub||e;Object.defineProperty(n.rootObj,n.propName,{set:t,configurable:o(n.rootObj,n.propName)});return e},value:function(e,t){const n=e.stub||e;Object.defineProperty(n.rootObj,n.propName,{value:t,enumerable:true,writable:true,configurable:n.shadowsPropOnPrototype||o(n.rootObj,n.propName)});return e}};const p=i(f);t.exports=s({},f,p)},{"./util/core/export-async-behaviors":25,"./util/core/extend":26,"./util/core/is-property-configurable":32,"@sinonjs/commons":47}],11:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./proxy");const i=e("./util/core/next-tick");const s=r.slice;t.exports=a;
/**
 * Returns a `fake` that records all calls, arguments and return values.
 *
 * When an `f` argument is supplied, this implementation will be used.
 *
 * @example
 * // create an empty fake
 * var f1 = sinon.fake();
 *
 * f1();
 *
 * f1.calledOnce()
 * // true
 *
 * @example
 * function greet(greeting) {
 *   console.log(`Hello ${greeting}`);
 * }
 *
 * // create a fake with implementation
 * var f2 = sinon.fake(greet);
 *
 * // Hello world
 * f2("world");
 *
 * f2.calledWith("world");
 * // true
 *
 * @param {Function|undefined} f
 * @returns {Function}
 * @namespace
 */function a(e){if(arguments.length>0&&typeof e!=="function")throw new TypeError("Expected f argument to be a Function");return l(e)}
/**
 * Creates a `fake` that returns the provided `value`, as well as recording all
 * calls, arguments and return values.
 *
 * @example
 * var f1 = sinon.fake.returns(42);
 *
 * f1();
 * // 42
 *
 * @memberof fake
 * @param {*} value
 * @returns {Function}
 */a.returns=function(e){function t(){return e}return l(t)};
/**
 * Creates a `fake` that throws an Error.
 * If the `value` argument does not have Error in its prototype chain, it will
 * be used for creating a new error.
 *
 * @example
 * var f1 = sinon.fake.throws("hello");
 *
 * f1();
 * // Uncaught Error: hello
 *
 * @example
 * var f2 = sinon.fake.throws(new TypeError("Invalid argument"));
 *
 * f2();
 * // Uncaught TypeError: Invalid argument
 *
 * @memberof fake
 * @param {*|Error} value
 * @returns {Function}
 */a.throws=function(e){function t(){throw u(e)}return l(t)};
/**
 * Creates a `fake` that returns a promise that resolves to the passed `value`
 * argument.
 *
 * @example
 * var f1 = sinon.fake.resolves("apple pie");
 *
 * await f1();
 * // "apple pie"
 *
 * @memberof fake
 * @param {*} value
 * @returns {Function}
 */a.resolves=function(e){function t(){return Promise.resolve(e)}return l(t)};
/**
 * Creates a `fake` that returns a promise that rejects to the passed `value`
 * argument. When `value` does not have Error in its prototype chain, it will be
 * wrapped in an Error.
 *
 * @example
 * var f1 = sinon.fake.rejects(":(");
 *
 * try {
 *   await f1();
 * } catch (error) {
 *   console.log(error);
 *   // ":("
 * }
 *
 * @memberof fake
 * @param {*} value
 * @returns {Function}
 */a.rejects=function(e){function t(){return Promise.reject(u(e))}return l(t)};
/**
 * Returns a `fake` that calls the callback with the defined arguments.
 *
 * @example
 * function callback() {
 *   console.log(arguments.join("*"));
 * }
 *
 * const f1 = sinon.fake.yields("apple", "pie");
 *
 * f1(callback);
 * // "apple*pie"
 *
 * @memberof fake
 * @returns {Function}
 */a.yields=function(){const e=s(arguments);function t(){const t=arguments[arguments.length-1];if(typeof t!=="function")throw new TypeError("Expected last argument to be a function");t.apply(null,e)}return l(t)};
/**
 * Returns a `fake` that calls the callback **asynchronously** with the
 * defined arguments.
 *
 * @example
 * function callback() {
 *   console.log(arguments.join("*"));
 * }
 *
 * const f1 = sinon.fake.yields("apple", "pie");
 *
 * f1(callback);
 *
 * setTimeout(() => {
 *   // "apple*pie"
 * });
 *
 * @memberof fake
 * @returns {Function}
 */a.yieldsAsync=function(){const e=s(arguments);function t(){const t=arguments[arguments.length-1];if(typeof t!=="function")throw new TypeError("Expected last argument to be a function");i((function(){t.apply(null,e)}))}return l(t)};let c=0;
/**
 * Creates a proxy (sinon concept) from the passed function.
 *
 * @private
 * @param  {Function} f
 * @returns {Function}
 */function l(e){const t=function(){let t,r;if(arguments.length>0){t=arguments[0];r=arguments[arguments.length-1]}const o=r&&typeof r==="function"?r:void 0;n.firstArg=t;n.lastArg=r;n.callback=o;return e&&e.apply(this,arguments)};const n=o(t,e||t);n.displayName="fake";n.id="fake#"+c++;return n}
/**
 * Returns an Error instance from the passed value, if the value is not
 * already an Error instance.
 *
 * @private
 * @param  {*} value [description]
 * @returns {Error}       [description]
 */function u(e){return e instanceof Error?e:new Error(e)}},{"./proxy":18,"./util/core/next-tick":34,"@sinonjs/commons":47}],12:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./proxy-invoke");const i=e("./proxy-call").toString;const s=e("./util/core/times-in-words");const a=e("./util/core/extend");const c=e("@sinonjs/samsam").createMatcher;const l=e("./stub");const u=e("./assert");const f=e("@sinonjs/samsam").deepEqual;const p=e("util").inspect;const h=e("@sinonjs/commons").valueToString;const d=r.every;const m=r.forEach;const y=r.push;const g=r.slice;function v(e){return e===0?"never called":`called ${s(e)}`}function b(e){const t=e.minCalls;const n=e.maxCalls;if(typeof t==="number"&&typeof n==="number"){let e=s(t);t!==n&&(e=`at least ${e} and at most ${s(n)}`);return e}return typeof t==="number"?`at least ${s(t)}`:`at most ${s(n)}`}function w(e){const t=typeof e.minCalls==="number";return!t||e.callCount>=e.minCalls}function x(e){return typeof e.maxCalls==="number"&&e.callCount===e.maxCalls}function j(e,t){const n=c.isMatcher(e);return n&&e.test(t)||true}const k={minCalls:1,maxCalls:1,create:function(e){const t=a.nonEnum(l(),k);delete t.create;t.method=e;return t},invoke:function(e,t,n){this.verifyCallAllowed(t,n);return o.apply(this,arguments)},atLeast:function(e){if(typeof e!=="number")throw new TypeError(`'${h(e)}' is not number`);if(!this.limitsSet){this.maxCalls=null;this.limitsSet=true}this.minCalls=e;return this},atMost:function(e){if(typeof e!=="number")throw new TypeError(`'${h(e)}' is not number`);if(!this.limitsSet){this.minCalls=null;this.limitsSet=true}this.maxCalls=e;return this},never:function(){return this.exactly(0)},once:function(){return this.exactly(1)},twice:function(){return this.exactly(2)},thrice:function(){return this.exactly(3)},exactly:function(e){if(typeof e!=="number")throw new TypeError(`'${h(e)}' is not a number`);this.atLeast(e);return this.atMost(e)},met:function(){return!this.failed&&w(this)},verifyCallAllowed:function(e,t){const n=this.expectedArguments;if(x(this)){this.failed=true;k.fail(`${this.method} already called ${s(this.maxCalls)}`)}"expectedThis"in this&&this.expectedThis!==e&&k.fail(`${this.method} called with ${h(e)} as thisValue, expected ${h(this.expectedThis)}`);if("expectedArguments"in this){t||k.fail(`${this.method} received no arguments, expected ${p(n)}`);t.length<n.length&&k.fail(`${this.method} received too few arguments (${p(t)}), expected ${p(n)}`);this.expectsExactArgCount&&t.length!==n.length&&k.fail(`${this.method} received too many arguments (${p(t)}), expected ${p(n)}`);m(n,(function(e,r){j(e,t[r])||k.fail(`${this.method} received wrong arguments ${p(t)}, didn't match ${String(n)}`);f(t[r],e)||k.fail(`${this.method} received wrong arguments ${p(t)}, expected ${p(n)}`)}),this)}},allowsCall:function(e,t){const n=this.expectedArguments;if(this.met()&&x(this))return false;if("expectedThis"in this&&this.expectedThis!==e)return false;if(!("expectedArguments"in this))return true;const r=t||[];return!(r.length<n.length)&&((!this.expectsExactArgCount||r.length===n.length)&&d(n,(function(e,t){return!!j(e,r[t])&&!!f(r[t],e)})))},withArgs:function(){this.expectedArguments=g(arguments);return this},withExactArgs:function(){this.withArgs.apply(this,arguments);this.expectsExactArgCount=true;return this},on:function(e){this.expectedThis=e;return this},toString:function(){const e=g(this.expectedArguments||[]);this.expectsExactArgCount||y(e,"[...]");const t=i.call({proxy:this.method||"anonymous mock expectation",args:e});const n=`${t.replace(", [...","[, ...")} ${b(this)}`;return this.met()?`Expectation met: ${n}`:`Expected ${n} (${v(this.callCount)})`},verify:function(){this.met()?k.pass(String(this)):k.fail(String(this));return true},pass:function(e){u.pass(e)},fail:function(e){const t=new Error(e);t.name="ExpectationError";throw t}};t.exports=k},{"./assert":4,"./proxy-call":16,"./proxy-invoke":17,"./stub":23,"./util/core/extend":26,"./util/core/times-in-words":36,"@sinonjs/commons":47,"@sinonjs/samsam":87,util:91}],13:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./mock-expectation");const i=e("./proxy-call").toString;const s=e("./util/core/extend");const a=e("@sinonjs/samsam").deepEqual;const c=e("./util/core/wrap-method");const l=r.concat;const u=r.filter;const f=r.forEach;const p=r.every;const h=r.join;const d=r.push;const m=r.slice;const y=r.unshift;function g(e){return e&&typeof e!=="string"?g.create(e):o.create(e||"Anonymous mock")}function v(e,t){const n=e||[];f(n,t)}function b(e,t,n){return(!n||e.length===t.length)&&p(e,(function(e,n){return a(t[n],e)}))}s(g,{create:function(e){if(!e)throw new TypeError("object is null");const t=s.nonEnum({},g,{object:e});delete t.create;return t},expects:function(e){if(!e)throw new TypeError("method is falsy");if(!this.expectations){this.expectations={};this.proxies=[];this.failures=[]}if(!this.expectations[e]){this.expectations[e]=[];const t=this;c(this.object,e,(function(){return t.invokeMethod(e,this,arguments)}));d(this.proxies,e)}const t=o.create(e);t.wrappedMethod=this.object[e].wrappedMethod;d(this.expectations[e],t);return t},restore:function(){const e=this.object;v(this.proxies,(function(t){typeof e[t].restore==="function"&&e[t].restore()}))},verify:function(){const e=this.expectations||{};const t=this.failures?m(this.failures):[];const n=[];v(this.proxies,(function(r){v(e[r],(function(e){e.met()?d(n,String(e)):d(t,String(e))}))}));this.restore();t.length>0?o.fail(h(l(t,n),"\n")):n.length>0&&o.pass(h(l(t,n),"\n"));return true},invokeMethod:function(e,t,n){const r=this.expectations&&this.expectations[e]?this.expectations[e]:[];const s=n||[];let a;const c=u(r,(function(e){const t=e.expectedArguments||[];return b(t,s,e.expectsExactArgCount)}));const l=u(c,(function(e){return!e.met()&&e.allowsCall(t,n)}));if(l.length>0)return l[0].apply(t,n);const p=[];let m=0;f(c,(function(e){e.allowsCall(t,n)?a=a||e:m+=1}));if(a&&m===0)return a.apply(t,n);f(r,(function(e){d(p,`    ${String(e)}`)}));y(p,`Unexpected call: ${i.call({proxy:e,args:n})}`);const g=new Error;if(!g.stack)try{throw g}catch(e){}d(this.failures,`Unexpected call: ${i.call({proxy:e,args:n,stack:g.stack})}`);o.fail(h(p,"\n"))}});t.exports=g},{"./mock-expectation":12,"./proxy-call":16,"./util/core/extend":26,"./util/core/wrap-method":39,"@sinonjs/commons":47,"@sinonjs/samsam":87}],14:[function(e,t,n){const r=e("./fake");const o=e("./util/core/is-restorable");const i="pending";const s="resolved";const a="rejected";
/**
 * Returns a fake for a given function or undefined. If no function is given, a
 * new fake is returned. If the given function is already a fake, it is
 * returned as is. Otherwise the given function is wrapped in a new fake.
 *
 * @param {Function} [executor] The optional executor function.
 * @returns {Function}
 */function c(e){return o(e)?e:e?r(e):r()}
/**
 * Returns a new promise that exposes it's internal `status`, `resolvedValue`
 * and `rejectedValue` and can be resolved or rejected from the outside by
 * calling `resolve(value)` or `reject(reason)`.
 *
 * @param {Function} [executor] The optional executor function.
 * @returns {Promise}
 */function l(e){const t=c(e);const n=new Promise(t);n.status=i;n.then((function(e){n.status=s;n.resolvedValue=e})).catch((function(e){n.status=a;n.rejectedValue=e}));
/**
     * Resolves or rejects the promise with the given status and value.
     *
     * @param {string} status
     * @param {*} value
     * @param {Function} callback
     */function r(e,t,r){if(n.status!==i)throw new Error(`Promise already ${n.status}`);n.status=e;r(t)}n.resolve=function(e){r(s,e,t.firstCall.args[0]);return n};n.reject=function(e){r(a,e,t.firstCall.args[1]);return new Promise((function(e){n.catch((()=>e()))}))};return n}t.exports=l},{"./fake":11,"./util/core/is-restorable":33}],15:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array.push;n.incrementCallCount=function(e){e.called=true;e.callCount+=1;e.notCalled=false;e.calledOnce=e.callCount===1;e.calledTwice=e.callCount===2;e.calledThrice=e.callCount===3};n.createCallProperties=function(e){e.firstCall=e.getCall(0);e.secondCall=e.getCall(1);e.thirdCall=e.getCall(2);e.lastCall=e.getCall(e.callCount-1)};n.delegateToCalls=function(e,t,n,o,i,s,a){e[t]=function(){if(!this.called)return!!s&&s.apply(this,arguments);if(a!==void 0&&this.callCount!==a)return false;let e;let c=0;const l=[];for(let i=0,s=this.callCount;i<s;i+=1){e=this.getCall(i);const s=e[o||t].apply(e,arguments);r(l,s);if(s){c+=1;if(n)return true}}return i?l:c===this.callCount}}},{"@sinonjs/commons":47}],16:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("@sinonjs/samsam").createMatcher;const i=e("@sinonjs/samsam").deepEqual;const s=e("@sinonjs/commons").functionName;const a=e("util").inspect;const c=e("@sinonjs/commons").valueToString;const l=r.concat;const u=r.filter;const f=r.join;const p=r.map;const h=r.reduce;const d=r.slice;
/**
 * @param proxy
 * @param text
 * @param args
 */function m(e,t,n){let r=s(e)+t;n.length&&(r+=` Received [${f(d(n),", ")}]`);throw new Error(r)}const y={calledOn:function(e){return o.isMatcher(e)?e.test(this.thisValue):this.thisValue===e},calledWith:function(){const e=this;const t=d(arguments);return!(t.length>e.args.length)&&h(t,(function(t,n,r){return t&&i(e.args[r],n)}),true)},calledWithMatch:function(){const e=this;const t=d(arguments);return!(t.length>e.args.length)&&h(t,(function(t,n,r){const i=e.args[r];return t&&o(n).test(i)}),true)},calledWithExactly:function(){return arguments.length===this.args.length&&this.calledWith.apply(this,arguments)},notCalledWith:function(){return!this.calledWith.apply(this,arguments)},notCalledWithMatch:function(){return!this.calledWithMatch.apply(this,arguments)},returned:function(e){return i(this.returnValue,e)},threw:function(e){return typeof e!=="undefined"&&this.exception?this.exception===e||this.exception.name===e:Boolean(this.exception)},calledWithNew:function(){return this.proxy.prototype&&this.thisValue instanceof this.proxy},calledBefore:function(e){return this.callId<e.callId},calledAfter:function(e){return this.callId>e.callId},calledImmediatelyBefore:function(e){return this.callId===e.callId-1},calledImmediatelyAfter:function(e){return this.callId===e.callId+1},callArg:function(e){this.ensureArgIsAFunction(e);return this.args[e]()},callArgOn:function(e,t){this.ensureArgIsAFunction(e);return this.args[e].apply(t)},callArgWith:function(e){return this.callArgOnWith.apply(this,l([e,null],d(arguments,1)))},callArgOnWith:function(e,t){this.ensureArgIsAFunction(e);const n=d(arguments,2);return this.args[e].apply(t,n)},throwArg:function(e){if(e>this.args.length)throw new TypeError(`Not enough arguments: ${e} required but only ${this.args.length} present`);throw this.args[e]},yield:function(){return this.yieldOn.apply(this,l([null],d(arguments,0)))},yieldOn:function(e){const t=d(this.args);const n=u(t,(function(e){return typeof e==="function"}))[0];n||m(this.proxy," cannot yield since no callback was passed.",t);return n.apply(e,d(arguments,1))},yieldTo:function(e){return this.yieldToOn.apply(this,l([e,null],d(arguments,1)))},yieldToOn:function(e,t){const n=d(this.args);const r=u(n,(function(t){return t&&typeof t[e]==="function"}))[0];const o=r&&r[e];o||m(this.proxy,` cannot yield to '${c(e)}' since no callback was passed.`,n);return o.apply(t,d(arguments,2))},toString:function(){if(!this.args)return":(";let e=this.proxy?`${String(this.proxy)}(`:"";const t=p(this.args,(function(e){return a(e)}));e=`${e+f(t,", ")})`;typeof this.returnValue!=="undefined"&&(e+=` => ${a(this.returnValue)}`);if(this.exception){e+=` !${this.exception.name}`;this.exception.message&&(e+=`(${this.exception.message})`)}this.stack&&(e+=(this.stack.split("\n")[3]||"unknown").replace(/^\s*(?:at\s+|@)?/," at "));return e},ensureArgIsAFunction:function(e){if(typeof this.args[e]!=="function")throw new TypeError(`Expected argument at position ${e} to be a Function, but was ${typeof this.args[e]}`)}};Object.defineProperty(y,"stack",{enumerable:true,configurable:true,get:function(){return this.errorWithCallStack&&this.errorWithCallStack.stack||""}});y.invokeCallback=y.yield;
/**
 * @param proxy
 * @param thisValue
 * @param args
 * @param returnValue
 * @param exception
 * @param id
 * @param errorWithCallStack
 *
 * @returns {object} proxyCall
 */function g(e,t,n,r,o,i,s){if(typeof i!=="number")throw new TypeError("Call id is not a number");let a,c;if(n.length>0){a=n[0];c=n[n.length-1]}const l=Object.create(y);const u=c&&typeof c==="function"?c:void 0;l.proxy=e;l.thisValue=t;l.args=n;l.firstArg=a;l.lastArg=c;l.callback=u;l.returnValue=r;l.exception=o;l.callId=i;l.errorWithCallStack=s;return l}g.toString=y.toString;t.exports=g},{"@sinonjs/commons":47,"@sinonjs/samsam":87,util:91}],17:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./proxy-call-util");const i=r.push;const s=r.forEach;const a=r.concat;const c=Error.prototype.constructor;const l=Function.prototype.bind;let u=0;t.exports=function(e,t,n){const r=this.matchingFakes(n);const f=u++;let p,h;o.incrementCallCount(this);i(this.thisValues,t);i(this.args,n);i(this.callIds,f);s(r,(function(e){o.incrementCallCount(e);i(e.thisValues,t);i(e.args,n);i(e.callIds,f)}));o.createCallProperties(this);s(r,o.createCallProperties);try{this.invoking=true;const r=this.getCall(this.callCount-1);if(r.calledWithNew()){h=new(l.apply(this.func||e,a([t],n)));typeof h!=="object"&&typeof h!=="function"&&(h=t)}else h=(this.func||e).apply(t,n)}catch(e){p=e}finally{delete this.invoking}i(this.exceptions,p);i(this.returnValues,h);s(r,(function(e){i(e.exceptions,p);i(e.returnValues,h)}));const d=new c;try{throw d}catch(e){}i(this.errorsWithCallStack,d);s(r,(function(e){i(e.errorsWithCallStack,d)}));o.createCallProperties(this);s(r,o.createCallProperties);if(p!==void 0)throw p;return h}},{"./proxy-call-util":15,"@sinonjs/commons":47}],18:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./util/core/extend");const i=e("./util/core/function-to-string");const s=e("./proxy-call");const a=e("./proxy-call-util");const c=e("./proxy-invoke");const l=e("util").inspect;const u=r.push;const f=r.forEach;const p=r.slice;const h=Object.freeze([]);const d={toString:i,named:function(e){this.displayName=e;const t=Object.getOwnPropertyDescriptor(this,"name");if(t&&t.configurable){t.value=e;Object.defineProperty(this,"name",t)}return this},invoke:c,matchingFakes:function(){return h},getCall:function(e){let t=e;t<0&&(t+=this.callCount);return t<0||t>=this.callCount?null:s(this,this.thisValues[t],this.args[t],this.returnValues[t],this.exceptions[t],this.callIds[t],this.errorsWithCallStack[t])},getCalls:function(){const e=[];let t;for(t=0;t<this.callCount;t++)u(e,this.getCall(t));return e},calledBefore:function(e){return!!this.called&&(!e.called||this.callIds[0]<e.callIds[e.callIds.length-1])},calledAfter:function(e){return!(!this.called||!e.called)&&this.callIds[this.callCount-1]>e.callIds[0]},calledImmediatelyBefore:function(e){return!(!this.called||!e.called)&&this.callIds[this.callCount-1]===e.callIds[e.callCount-1]-1},calledImmediatelyAfter:function(e){return!(!this.called||!e.called)&&this.callIds[this.callCount-1]===e.callIds[e.callCount-1]+1},formatters:e("./spy-formatters"),printf:function(e){const t=this;const n=p(arguments,1);let r;return(e||"").replace(/%(.)/g,(function(e,o){r=d.formatters[o];return typeof r==="function"?String(r(t,n)):isNaN(parseInt(o,10))?`%${o}`:l(n[o-1])}))},resetHistory:function(){if(this.invoking){const e=new Error("Cannot reset Sinon function while invoking it. Move the call to .resetHistory outside of the callback.");e.name="InvalidResetException";throw e}this.called=false;this.notCalled=true;this.calledOnce=false;this.calledTwice=false;this.calledThrice=false;this.callCount=0;this.firstCall=null;this.secondCall=null;this.thirdCall=null;this.lastCall=null;this.args=[];this.firstArg=null;this.lastArg=null;this.returnValues=[];this.thisValues=[];this.exceptions=[];this.callIds=[];this.errorsWithCallStack=[];this.fakes&&f(this.fakes,(function(e){e.resetHistory()}));return this}};const m=a.delegateToCalls;m(d,"calledOn",true);m(d,"alwaysCalledOn",false,"calledOn");m(d,"calledWith",true);m(d,"calledOnceWith",true,"calledWith",false,void 0,1);m(d,"calledWithMatch",true);m(d,"alwaysCalledWith",false,"calledWith");m(d,"alwaysCalledWithMatch",false,"calledWithMatch");m(d,"calledWithExactly",true);m(d,"calledOnceWithExactly",true,"calledWithExactly",false,void 0,1);m(d,"calledOnceWithMatch",true,"calledWithMatch",false,void 0,1);m(d,"alwaysCalledWithExactly",false,"calledWithExactly");m(d,"neverCalledWith",false,"notCalledWith",false,(function(){return true}));m(d,"neverCalledWithMatch",false,"notCalledWithMatch",false,(function(){return true}));m(d,"threw",true);m(d,"alwaysThrew",false,"threw");m(d,"returned",true);m(d,"alwaysReturned",false,"returned");m(d,"calledWithNew",true);m(d,"alwaysCalledWithNew",false,"calledWithNew");function y(e,t){const n=g(e,t);o(n,e);n.prototype=e.prototype;o.nonEnum(n,d);return n}function g(e,t){const n=t.length;let r;switch(n){case 0:r=function(){return r.invoke(e,this,p(arguments))};break;case 1:r=function(t){return r.invoke(e,this,p(arguments))};break;case 2:r=function(t,n){return r.invoke(e,this,p(arguments))};break;case 3:r=function(t,n,o){return r.invoke(e,this,p(arguments))};break;case 4:r=function(t,n,o,i){return r.invoke(e,this,p(arguments))};break;case 5:r=function(t,n,o,i,s){return r.invoke(e,this,p(arguments))};break;case 6:r=function(t,n,o,i,s,a){return r.invoke(e,this,p(arguments))};break;case 7:r=function(t,n,o,i,s,a,c){return r.invoke(e,this,p(arguments))};break;case 8:r=function(t,n,o,i,s,a,c,l){return r.invoke(e,this,p(arguments))};break;case 9:r=function(t,n,o,i,s,a,c,l,u){return r.invoke(e,this,p(arguments))};break;case 10:r=function(t,n,o,i,s,a,c,l,u,f){return r.invoke(e,this,p(arguments))};break;case 11:r=function(t,n,o,i,s,a,c,l,u,f,h){return r.invoke(e,this,p(arguments))};break;case 12:r=function(t,n,o,i,s,a,c,l,u,f,h,d){return r.invoke(e,this,p(arguments))};break;default:r=function(){return r.invoke(e,this,p(arguments))};break}const i=Object.getOwnPropertyDescriptor(t,"name");i&&i.configurable&&Object.defineProperty(r,"name",i);o.nonEnum(r,{isSinonProxy:true,called:false,notCalled:true,calledOnce:false,calledTwice:false,calledThrice:false,callCount:0,firstCall:null,firstArg:null,secondCall:null,thirdCall:null,lastCall:null,lastArg:null,args:[],returnValues:[],thisValues:[],exceptions:[],callIds:[],errorsWithCallStack:[]});return r}t.exports=y},{"./proxy-call":16,"./proxy-call-util":15,"./proxy-invoke":17,"./spy-formatters":21,"./util/core/extend":26,"./util/core/function-to-string":27,"@sinonjs/commons":47,util:91}],19:[function(e,t,n){const r=e("./util/core/walk-object");function o(e,t){return e[t].restore&&e[t].restore.sinon}function i(e,t){e[t].restore()}function s(e){return r(i,e,o)}t.exports=s},{"./util/core/walk-object":37}],20:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("@sinonjs/commons").deprecated;const i=e("./collect-own-methods");const s=e("./util/core/get-property-descriptor");const a=e("./util/core/is-property-configurable");const c=e("@sinonjs/samsam").createMatcher;const l=e("./assert");const u=e("./util/fake-timers");const f=e("./mock");const p=e("./spy");const h=e("./stub");const d=e("./create-stub-instance");const m=e("./fake");const y=e("@sinonjs/commons").valueToString;const g=1e4;const v=r.filter;const b=r.forEach;const w=r.push;const x=r.reverse;function j(e,t){const n=v(e,(function(e){return typeof e[t]==="function"}));b(n,(function(e){e[t]()}))}function k(e){if(typeof e.get==="function")throw new Error("Use sandbox.replaceGetter for replacing getters");if(typeof e.set==="function")throw new Error("Use sandbox.replaceSetter for replacing setters")}function A(e,t,n){if(typeof e[t]!==typeof n)throw new TypeError(`Cannot replace ${typeof e[t]} with ${typeof n}`)}function T(e,t,n){if(typeof e==="undefined")throw new TypeError(`Cannot replace non-existent property ${y(t)}. Perhaps you meant sandbox.define()?`);if(typeof n==="undefined")throw new TypeError("Expected replacement argument to be defined")}
/**
 * A sinon sandbox
 *
 * @param opts
 * @param {object} [opts.assertOptions] see the CreateAssertOptions in ./assert
 * @class
 */function O(e={}){const t=this;const n=e.assertOptions||{};let r=[];let v=[];let O=false;t.leakThreshold=g;function C(e){if(w(v,e)>t.leakThreshold&&!O){o.printWarning("Potential memory leak detected; be sure to call restore() to clean up your sandbox. To suppress this warning, modify the leakThreshold property of your sandbox.");O=true}}t.assert=l.createAssertObject(n);t.getFakes=function(){return v};t.createStubInstance=function(){const e=d.apply(null,arguments);const t=i(e);b(t,(function(e){C(e)}));return e};t.inject=function(e){e.spy=function(){return t.spy.apply(null,arguments)};e.stub=function(){return t.stub.apply(null,arguments)};e.mock=function(){return t.mock.apply(null,arguments)};e.createStubInstance=function(){return t.createStubInstance.apply(t,arguments)};e.fake=function(){return t.fake.apply(null,arguments)};e.define=function(){return t.define.apply(null,arguments)};e.replace=function(){return t.replace.apply(null,arguments)};e.replaceSetter=function(){return t.replaceSetter.apply(null,arguments)};e.replaceGetter=function(){return t.replaceGetter.apply(null,arguments)};t.clock&&(e.clock=t.clock);e.match=c;return e};t.mock=function(){const e=f.apply(null,arguments);C(e);return e};t.reset=function(){j(v,"reset");j(v,"resetHistory")};t.resetBehavior=function(){j(v,"resetBehavior")};t.resetHistory=function(){function e(e){const t=e.resetHistory||e.reset;t&&t.call(e)}b(v,e)};t.restore=function(){if(arguments.length)throw new Error("sandbox.restore() does not take any parameters. Perhaps you meant stub.restore()");x(v);j(v,"restore");v=[];b(r,(function(e){e()}));r=[];t.restoreContext()};t.restoreContext=function(){if(t.injectedKeys){b(t.injectedKeys,(function(e){delete t.injectInto[e]}));t.injectedKeys.length=0}};
/**
     * Creates a restorer function for the property
     *
     * @param {object|Function} object
     * @param {string} property
     * @param {boolean} forceAssignment
     * @returns {Function} restorer function
     */function E(e,t,n=false){const r=s(e,t);const o=n&&e[t];function i(){n?e[t]=o:r?.isOwn?Object.defineProperty(e,t,r):delete e[t]}i.object=e;i.property=t;return i}function S(e,t){b(r,(function(n){if(n.object===e&&n.property===t)throw new TypeError(`Attempted to replace ${t} which is already replaced`)}))}
/**
     * Replace an existing property
     *
     * @param {object|Function} object
     * @param {string} property
     * @param {*} replacement a fake, stub, spy or any other value
     * @returns {*}
     */t.replace=function(e,t,n){const o=s(e,t);T(o,t,n);k(o);A(e,t,n);S(e,t);w(r,E(e,t));e[t]=n;return n};t.replace.usingAccessor=function(e,t,n){const o=s(e,t);T(o,t,n);A(e,t,n);S(e,t);w(r,E(e,t,true));e[t]=n;return n};t.define=function(e,t,n){const o=s(e,t);if(o)throw new TypeError(`Cannot define the already existing property ${y(t)}. Perhaps you meant sandbox.replace()?`);if(typeof n==="undefined")throw new TypeError("Expected value argument to be defined");S(e,t);w(r,E(e,t));e[t]=n;return n};t.replaceGetter=function(e,t,n){const o=s(e,t);if(typeof o==="undefined")throw new TypeError(`Cannot replace non-existent property ${y(t)}`);if(typeof n!=="function")throw new TypeError("Expected replacement argument to be a function");if(typeof o.get!=="function")throw new Error("`object.property` is not a getter");S(e,t);w(r,E(e,t));Object.defineProperty(e,t,{get:n,configurable:a(e,t)});return n};t.replaceSetter=function(e,t,n){const o=s(e,t);if(typeof o==="undefined")throw new TypeError(`Cannot replace non-existent property ${y(t)}`);if(typeof n!=="function")throw new TypeError("Expected replacement argument to be a function");if(typeof o.set!=="function")throw new Error("`object.property` is not a setter");S(e,t);w(r,E(e,t));Object.defineProperty(e,t,{set:n,configurable:a(e,t)});return n};function P(e,t){const[n,r,o]=e;const s=typeof r==="undefined"&&typeof n==="object";if(s){const e=i(t);b(e,(function(e){C(e)}))}else if(Array.isArray(o))for(const e of o)C(t[e]);else C(t);return t}t.spy=function(){const e=p.apply(p,arguments);return P(arguments,e)};t.stub=function(){const e=h.apply(h,arguments);return P(arguments,e)};t.fake=function(e){const t=m.apply(m,arguments);C(t);return t};b(Object.keys(m),(function(e){const n=m[e];typeof n==="function"&&(t.fake[e]=function(){const e=n.apply(n,arguments);C(e);return e})}));t.useFakeTimers=function(e){const n=u.useFakeTimers.call(null,e);t.clock=n;C(n);return n};t.verify=function(){j(v,"verify")};t.verifyAndRestore=function(){let e;try{t.verify()}catch(t){e=t}t.restore();if(e)throw e}}O.prototype.match=c;t.exports=O},{"./assert":4,"./collect-own-methods":6,"./create-stub-instance":9,"./fake":11,"./mock":13,"./spy":22,"./stub":23,"./util/core/get-property-descriptor":29,"./util/core/is-property-configurable":32,"./util/fake-timers":40,"@sinonjs/commons":47,"@sinonjs/samsam":87}],21:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./colorizer");const i=new o;const s=e("@sinonjs/samsam").createMatcher;const a=e("./util/core/times-in-words");const c=e("util").inspect;const l=e("diff");const u=r.join;const f=r.map;const p=r.push;const h=r.slice;
/**
 *
 * @param matcher
 * @param calledArg
 * @param calledArgMessage
 *
 * @returns {string} the colored text
 */function d(e,t,n){let r=n;let o=e.message;if(!e.test(t)){o=i.red(e.message);r&&(r=i.green(r))}return`${r} ${o}`}
/**
 * @param diff
 *
 * @returns {string} the colored diff
 */function m(e){const t=f(e,(function(t){let n=t.value;t.added?n=i.green(n):t.removed&&(n=i.red(n));e.length===2&&(n+=" ");return n}));return u(t,"")}
/**
 *
 * @param value
 * @returns {string} a quoted string
 */function y(e){return typeof e==="string"?JSON.stringify(e):e}t.exports={c:function(e){return a(e.callCount)},n:function(e){return e.toString()},D:function(e,t){let n="";for(let r=0,o=e.callCount;r<o;++r){o>1&&(n+=`\nCall ${r+1}:`);const i=e.getCall(r).args;const a=h(t);for(let e=0;e<i.length||e<a.length;++e){let t=i[e];let r=a[e];t&&(t=y(t));r&&(r=y(r));n+="\n";const o=e<i.length?c(t):"";if(s.isMatcher(r))n+=d(r,t,o);else{const t=e<a.length?c(r):"";const i=l.diffJson(o,t);n+=m(i)}}}return n},C:function(e){const t=[];for(let n=0,r=e.callCount;n<r;++n){let r=`    ${e.getCall(n).toString()}`;/\n/.test(t[n-1])&&(r=`\n${r}`);p(t,r)}return t.length>0?`\n${u(t,"\n")}`:""},t:function(e){const t=[];for(let n=0,r=e.callCount;n<r;++n)p(t,c(e.thisValues[n]));return u(t,", ")},"*":function(e,t){return u(f(t,(function(e){return c(e)})),", ")}}},{"./colorizer":7,"./util/core/times-in-words":36,"@sinonjs/commons":47,"@sinonjs/samsam":87,diff:92,util:91}],22:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./proxy");const i=e("./util/core/extend");const s=e("@sinonjs/commons").functionName;const a=e("./util/core/get-property-descriptor");const c=e("@sinonjs/samsam").deepEqual;const l=e("./util/core/is-es-module");const u=e("./proxy-call-util");const f=e("./util/core/walk-object");const p=e("./util/core/wrap-method");const h=e("@sinonjs/commons").valueToString;const d=r.forEach;const m=r.pop;const y=r.push;const g=r.slice;const v=Array.prototype.filter;let b=0;function w(e,t,n){const r=e.matchingArguments;return!!(r.length<=t.length&&c(g(t,0,r.length),r))&&(!n||r.length===t.length)}const x={withArgs:function(){const e=g(arguments);const t=m(this.matchingFakes(e,true));if(t)return t;const n=this;const r=this.instantiateFake();r.matchingArguments=e;r.parent=this;y(this.fakes,r);r.withArgs=function(){return n.withArgs.apply(n,arguments)};d(n.args,(function(e,t){if(w(r,e)){u.incrementCallCount(r);y(r.thisValues,n.thisValues[t]);y(r.args,e);y(r.returnValues,n.returnValues[t]);y(r.exceptions,n.exceptions[t]);y(r.callIds,n.callIds[t])}}));u.createCallProperties(r);return r},matchingFakes:function(e,t){return v.call(this.fakes,(function(n){return w(n,e,t)}))}};const j=u.delegateToCalls;j(x,"callArg",false,"callArgWith",true,(function(){throw new Error(`${this.toString()} cannot call arg since it was not yet invoked.`)}));x.callArgWith=x.callArg;j(x,"callArgOn",false,"callArgOnWith",true,(function(){throw new Error(`${this.toString()} cannot call arg since it was not yet invoked.`)}));x.callArgOnWith=x.callArgOn;j(x,"throwArg",false,"throwArg",false,(function(){throw new Error(`${this.toString()} cannot throw arg since it was not yet invoked.`)}));j(x,"yield",false,"yield",true,(function(){throw new Error(`${this.toString()} cannot yield since it was not yet invoked.`)}));x.invokeCallback=x.yield;j(x,"yieldOn",false,"yieldOn",true,(function(){throw new Error(`${this.toString()} cannot yield since it was not yet invoked.`)}));j(x,"yieldTo",false,"yieldTo",true,(function(e){throw new Error(`${this.toString()} cannot yield to '${h(e)}' since it was not yet invoked.`)}));j(x,"yieldToOn",false,"yieldToOn",true,(function(e){throw new Error(`${this.toString()} cannot yield to '${h(e)}' since it was not yet invoked.`)}));function k(e){let t;let n=e;typeof n!=="function"?n=function(){}:t=s(n);const r=o(n,n);i.nonEnum(r,x);i.nonEnum(r,{displayName:t||"spy",fakes:[],instantiateFake:k,id:"spy#"+b++});return r}function A(e,t,n){if(l(e))throw new TypeError("ES Modules cannot be spied");if(!t&&typeof e==="function")return k(e);if(!t&&typeof e==="object")return f(A,e);if(!e&&!t)return k((function(){}));if(!n)return p(e,t,k(e[t]));const r={};const o=a(e,t);d(n,(function(e){r[e]=k(o[e])}));return p(e,t,r)}i(A,x);t.exports=A},{"./proxy":18,"./proxy-call-util":15,"./util/core/extend":26,"./util/core/get-property-descriptor":29,"./util/core/is-es-module":30,"./util/core/walk-object":37,"./util/core/wrap-method":39,"@sinonjs/commons":47,"@sinonjs/samsam":87}],23:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("./behavior");const i=e("./default-behaviors");const s=e("./proxy");const a=e("@sinonjs/commons").functionName;const c=e("@sinonjs/commons").prototypes.object.hasOwnProperty;const l=e("./util/core/is-non-existent-property");const u=e("./spy");const f=e("./util/core/extend");const p=e("./util/core/get-property-descriptor");const h=e("./util/core/is-es-module");const d=e("./util/core/sinon-type");const m=e("./util/core/wrap-method");const y=e("./throw-on-falsy-object");const g=e("@sinonjs/commons").valueToString;const v=e("./util/core/walk-object");const b=r.forEach;const w=r.pop;const x=r.slice;const j=r.sort;let k=0;function A(e){let t;function n(){const e=x(arguments);const n=t.matchingFakes(e);const r=w(j(n,(function(e,t){return e.matchingArguments.length-t.matchingArguments.length})))||t;return P(r).invoke(this,arguments)}t=s(n,e||n);f.nonEnum(t,u);f.nonEnum(t,T);const r=e?a(e):null;f.nonEnum(t,{fakes:[],instantiateFake:A,displayName:r||"stub",defaultBehavior:null,behaviors:[],id:"stub#"+k++});d.set(t,"stub");return t}function T(e,t){if(arguments.length>2)throw new TypeError("stub(obj, 'meth', fn) has been removed, see documentation");if(h(e))throw new TypeError("ES Modules cannot be stubbed");y.apply(null,arguments);if(l(e,t))throw new TypeError(`Cannot stub non-existent property ${g(t)}`);const n=p(e,t);O(n,t);const r=typeof e==="object"||typeof e==="function";const o=typeof t==="undefined"&&r;const i=!e&&typeof t==="undefined";const s=r&&typeof t!=="undefined"&&(typeof n==="undefined"||typeof n.value!=="function");if(o)return v(T,e);if(i)return A();const a=typeof n.value==="function"?n.value:null;const c=A(a);f.nonEnum(c,{rootObj:e,propName:t,shadowsPropOnPrototype:!n.isOwn,restore:function(){n!==void 0&&n.isOwn?Object.defineProperty(e,t,n):delete e[t]}});return s?c:m(e,t,c)}function O(e,t){if(e&&t){if(e.isOwn&&!e.configurable&&!e.writable)throw new TypeError(`Descriptor for property ${t} is non-configurable and non-writable`);if((e.get||e.set)&&!e.configurable)throw new TypeError(`Descriptor for accessor property ${t} is non-configurable`);if(C(e)&&!e.writable)throw new TypeError(`Descriptor for data property ${t} is non-writable`)}}function C(e){return!e.value&&!e.writable&&!e.set&&!e.get}function E(e){return e.parent&&P(e.parent)}function S(e){return e.defaultBehavior||E(e)||o.create(e)}function P(e){const t=e.behaviors[e.callCount-1];return t&&t.isPresent()?t:S(e)}const $={resetBehavior:function(){this.defaultBehavior=null;this.behaviors=[];delete this.returnValue;delete this.returnArgAt;delete this.throwArgAt;delete this.resolveArgAt;delete this.fakeFn;this.returnThis=false;this.resolveThis=false;b(this.fakes,(function(e){e.resetBehavior()}))},reset:function(){this.resetHistory();this.resetBehavior()},onCall:function(e){this.behaviors[e]||(this.behaviors[e]=o.create(this));return this.behaviors[e]},onFirstCall:function(){return this.onCall(0)},onSecondCall:function(){return this.onCall(1)},onThirdCall:function(){return this.onCall(2)},withArgs:function(){const e=u.withArgs.apply(this,arguments);if(this.defaultBehavior&&this.defaultBehavior.promiseLibrary){e.defaultBehavior=e.defaultBehavior||o.create(e);e.defaultBehavior.promiseLibrary=this.defaultBehavior.promiseLibrary}return e}};b(Object.keys(o),(function(e){c(o,e)&&!c($,e)&&e!=="create"&&e!=="invoke"&&($[e]=o.createBehavior(e))}));b(Object.keys(i),(function(e){c(i,e)&&!c($,e)&&o.addBehavior(T,e,i[e])}));f(T,$);t.exports=T},{"./behavior":5,"./default-behaviors":10,"./proxy":18,"./spy":22,"./throw-on-falsy-object":24,"./util/core/extend":26,"./util/core/get-property-descriptor":29,"./util/core/is-es-module":30,"./util/core/is-non-existent-property":31,"./util/core/sinon-type":35,"./util/core/walk-object":37,"./util/core/wrap-method":39,"@sinonjs/commons":47}],24:[function(e,t,n){const r=e("@sinonjs/commons").valueToString;function o(e,t){if(t&&!e){const n=e===null?"null":"undefined";throw new Error(`Trying to stub property '${r(t)}' of ${n}`)}}t.exports=o},{"@sinonjs/commons":47}],25:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=r.reduce;t.exports=function(e){return o(Object.keys(e),(function(t,n){n.match(/^(callsArg|yields)/)&&!n.match(/Async/)&&(t[`${n}Async`]=function(){const t=e[n].apply(this,arguments);this.callbackAsync=true;return t});return t}),{})}},{"@sinonjs/commons":47}],26:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array;const o=e("@sinonjs/commons").prototypes.object.hasOwnProperty;const i=r.join;const s=r.push;const a=function(){const e={constructor:function(){return"0"},toString:function(){return"1"},valueOf:function(){return"2"},toLocaleString:function(){return"3"},prototype:function(){return"4"},isPrototypeOf:function(){return"5"},propertyIsEnumerable:function(){return"6"},hasOwnProperty:function(){return"7"},length:function(){return"8"},unique:function(){return"9"}};const t=[];for(const n in e)o(e,n)&&s(t,e[n]());return i(t,"")!=="0123456789"}();
/**
 *
 * @param target
 * @param sources
 * @param doCopy
 * @returns {*} target
 */function c(e,t,n){let r,i,s;for(i=0;i<t.length;i++){r=t[i];for(s in r)o(r,s)&&n(e,r,s);a&&o(r,"toString")&&r.toString!==e.toString&&(e.toString=r.toString)}return e}
/**
 * Public: Extend target in place with all (own) properties, except 'name' when [[writable]] is false,
 *         from sources in-order. Thus, last source will override properties in previous sources.
 *
 * @param {object} target - The Object to extend
 * @param {object[]} sources - Objects to copy properties from.
 * @returns {object} the extended target
 */t.exports=function(e,...t){return c(e,t,(function(e,t,n){const r=Object.getOwnPropertyDescriptor(e,n);const i=Object.getOwnPropertyDescriptor(t,n);if(n==="name"&&!r.writable)return;const s={configurable:i.configurable,enumerable:i.enumerable};if(o(i,"writable")){s.writable=i.writable;s.value=i.value}else{i.get&&(s.get=i.get.bind(e));i.set&&(s.set=i.set.bind(e))}Object.defineProperty(e,n,s)}))};
/**
 * Public: Extend target in place with all (own) properties from sources in-order. Thus, last source will
 *         override properties in previous sources. Define the properties as non enumerable.
 *
 * @param {object} target - The Object to extend
 * @param {object[]} sources - Objects to copy properties from.
 * @returns {object} the extended target
 */t.exports.nonEnum=function(e,...t){return c(e,t,(function(e,t,n){Object.defineProperty(e,n,{value:t[n],enumerable:false,configurable:true,writable:true})}))}},{"@sinonjs/commons":47}],27:[function(e,t,n){t.exports=function(){let e,t,n;if(this.getCall&&this.callCount){e=this.callCount;while(e--){n=this.getCall(e).thisValue;for(t in n)try{if(n[t]===this)return t}catch(e){}}}return this.displayName||"sinon fake"}},{}],28:[function(e,t,n){function r(e){setTimeout(e,0)}t.exports=function(e,t){return typeof e==="object"&&typeof e.nextTick==="function"?e.nextTick:typeof t==="function"?t:r}},{}],29:[function(e,t,n){
/**
 * @typedef {object} PropertyDescriptor
 * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty#description
 * @property {boolean} configurable defaults to false
 * @property {boolean} enumerable   defaults to false
 * @property {boolean} writable     defaults to false
 * @property {*} value defaults to undefined
 * @property {Function} get defaults to undefined
 * @property {Function} set defaults to undefined
 */
/**
 * @typedef {{isOwn: boolean} & PropertyDescriptor} SinonPropertyDescriptor
 * a slightly enriched property descriptor
 * @property {boolean} isOwn true if the descriptor is owned by this object, false if it comes from the prototype
 */
/**
 * Returns a slightly modified property descriptor that one can tell is from the object or the prototype
 *
 * @param {*} object
 * @param {string} property
 * @returns {SinonPropertyDescriptor}
 */
function r(e,t){let n=e;let r;const o=Boolean(e&&Object.getOwnPropertyDescriptor(e,t));while(n&&!(r=Object.getOwnPropertyDescriptor(n,t)))n=Object.getPrototypeOf(n);r&&(r.isOwn=o);return r}t.exports=r},{}],30:[function(e,t,n){
/**
 * Verify if an object is a ECMAScript Module
 *
 * As the exports from a module is immutable we cannot alter the exports
 * using spies or stubs. Let the consumer know this to avoid bug reports
 * on weird error messages.
 *
 * @param {object} object The object to examine
 * @returns {boolean} true when the object is a module
 */
t.exports=function(e){return e&&typeof Symbol!=="undefined"&&e[Symbol.toStringTag]==="Module"&&Object.isSealed(e)}},{}],31:[function(e,t,n){
/**
 * @param {*} object
 * @param {string} property
 * @returns {boolean} whether a prop exists in the prototype chain
 */
function r(e,t){return Boolean(e&&typeof t!=="undefined"&&!(t in e))}t.exports=r},{}],32:[function(e,t,n){const r=e("./get-property-descriptor");function o(e,t){const n=r(e,t);return!n||n.configurable}t.exports=o},{"./get-property-descriptor":29}],33:[function(e,t,n){function r(e){return typeof e==="function"&&typeof e.restore==="function"&&e.restore.sinon}t.exports=r},{}],34:[function(e,t,n){const r=e("@sinonjs/commons").global;const o=e("./get-next-tick");t.exports=o(r.process,r.setImmediate)},{"./get-next-tick":28,"@sinonjs/commons":47}],35:[function(e,t,n){const r=Symbol("SinonType");t.exports={
/**
     * Set the type of a Sinon object to make it possible to identify it later at runtime
     *
     * @param {object|Function} object  object/function to set the type on
     * @param {string} type the named type of the object/function
     */
set(e,t){Object.defineProperty(e,r,{value:t,configurable:false,enumerable:false})},get(e){return e&&e[r]}}},{}],36:[function(e,t,n){const r=[null,"once","twice","thrice"];t.exports=function(e){return r[e]||`${e||0} times`}},{}],37:[function(e,t,n){const r=e("@sinonjs/commons").functionName;const o=e("./get-property-descriptor");const i=e("./walk");
/**
 * A utility that allows traversing an object, applying mutating functions on the properties
 *
 * @param {Function} mutator called on each property
 * @param {object} object the object we are walking over
 * @param {Function} filter a predicate (boolean function) that will decide whether or not to apply the mutator to the current property
 * @returns {void} nothing
 */function s(e,t,n){let s=false;const a=r(e);if(!t)throw new Error(`Trying to ${a} object but received ${String(t)}`);i(t,(function(r,i){if(i!==Object.prototype&&r!=="constructor"&&typeof o(i,r).value==="function")if(n){if(n(t,r)){s=true;e(t,r)}}else{s=true;e(t,r)}}));if(!s)throw new Error("Found no methods on object to which we could apply mutations");return t}t.exports=s},{"./get-property-descriptor":29,"./walk":38,"@sinonjs/commons":47}],38:[function(e,t,n){const r=e("@sinonjs/commons").prototypes.array.forEach;function o(e,t,n,i,s){let a;const c=Object.getPrototypeOf(e);if(typeof Object.getOwnPropertyNames==="function"){r(Object.getOwnPropertyNames(e),(function(r){if(s[r]!==true){s[r]=true;const o=typeof Object.getOwnPropertyDescriptor(e,r).get==="function"?i:e;t.call(n,r,o)}}));c&&o(c,t,n,i,s)}else for(a in e)t.call(n,e[a],a,e)}t.exports=function(e,t,n){return o(e,t,n,e,{})}},{"@sinonjs/commons":47}],39:[function(e,t,n){const r=()=>{};const o=e("./get-property-descriptor");const i=e("./extend");const s=e("./sinon-type");const a=e("@sinonjs/commons").prototypes.object.hasOwnProperty;const c=e("@sinonjs/commons").valueToString;const l=e("@sinonjs/commons").prototypes.array.push;function u(e){return typeof e==="function"||Boolean(e&&e.constructor&&e.call&&e.apply)}function f(e,t){for(const n in t)a(e,n)||(e[n]=t[n])}function p(e,t,n){const r=["get","set"];const i=o(e,t);for(let e=0;e<r.length;e++)if(i[r[e]]&&i[r[e]].name===n.name)return r[e];return null}const h="keys"in Object;t.exports=function(e,t,n){if(!e)throw new TypeError("Should wrap property of object");if(typeof n!=="function"&&typeof n!=="object")throw new TypeError("Method wrapper should be a function or a property descriptor");function d(e){let n;if(u(e)){if(e.restore&&e.restore.sinon)n=new TypeError(`Attempted to wrap ${c(t)} which is already wrapped`);else if(e.calledBefore){const r=e.returns?"stubbed":"spied on";n=new TypeError(`Attempted to wrap ${c(t)} which is already ${r}`)}}else n=new TypeError(`Attempted to wrap ${typeof e} property ${c(t)} as function`);if(n){e&&e.stackTraceError&&(n.stack+=`\n--------------\n${e.stackTraceError.stack}`);throw n}}let m,y,g,v,b,w;const x=[];function j(){y=e[t];d(y);e[t]=n;n.displayName=t}const k=e.hasOwnProperty?e.hasOwnProperty(t):a(e,t);if(h){const r=typeof n==="function"?{value:n}:n;v=o(e,t);v?v.restore&&v.restore.sinon&&(m=new TypeError(`Attempted to wrap ${t} which is already wrapped`)):m=new TypeError(`Attempted to wrap ${typeof y} property ${t} as function`);if(m){v&&v.stackTraceError&&(m.stack+=`\n--------------\n${v.stackTraceError.stack}`);throw m}const i=Object.keys(r);for(g=0;g<i.length;g++){y=v[i[g]];d(y);l(x,y)}f(r,v);for(g=0;g<i.length;g++)f(r[i[g]],v[i[g]]);k||(r.configurable=true);Object.defineProperty(e,t,r);if(typeof n==="function"&&e[t]!==n){delete e[t];j()}}else j();A();function A(){for(g=0;g<x.length;g++){w=p(e,t,x[g]);b=w?n[w]:n;i.nonEnum(b,{displayName:t,wrappedMethod:x[g],stackTraceError:new Error("Stack Trace for original"),restore:T});b.restore.sinon=true;h||f(b,y)}}function T(){w=p(e,t,this.wrappedMethod);let n;if(w){if(k){if(h){n=o(e,t);n[w]=v[w];Object.defineProperty(e,t,n)}}else try{delete e[t][w]}catch(e){}if(h){n=o(e,t);n&&n.value===b&&(e[t][w]=this.wrappedMethod)}else e[t][w]===b&&(e[t][w]=this.wrappedMethod)}else{if(k)h&&Object.defineProperty(e,t,v);else try{delete e[t]}catch(e){}if(h){n=o(e,t);n&&n.value===b&&(e[t]=this.wrappedMethod)}else e[t]===b&&(e[t]=this.wrappedMethod)}s.get(e)==="stub-instance"&&(e[t]=r)}return n}},{"./extend":26,"./get-property-descriptor":29,"./sinon-type":35,"@sinonjs/commons":47}],40:[function(e,t,n){const r=e("./core/extend");const o=e("@sinonjs/fake-timers");const i=e("@sinonjs/commons").global;
/**
 *
 * @param config
 * @param globalCtx
 *
 * @returns {object} the clock, after installing it on the global context, if given
 */function s(e,t){let n=o;t!==null&&typeof t==="object"&&(n=o.withGlobal(t));const r=n.install(e);r.restore=r.uninstall;return r}
/**
 *
 * @param obj
 * @param globalPropName
 */function a(e,t){const n=i[t];typeof n!=="undefined"&&(e[t]=n)}
/**
 * @param {number|Date|object} dateOrConfig The unix epoch value to install with (default 0)
 * @returns {object} Returns a lolex clock instance
 */n.useFakeTimers=function(e){const t=typeof e!=="undefined";const n=(typeof e==="number"||e instanceof Date)&&arguments.length===1;const o=e!==null&&typeof e==="object"&&arguments.length===1;if(!t)return s({now:0});if(n)return s({now:e});if(o){const t=r.nonEnum({},e);const n=t.global;delete t.global;return s(t,n)}throw new TypeError("useFakeTimers expected epoch or config object. See https://github.com/sinonjs/sinon")};n.clock={create:function(e){return o.createClock(e)}};const c={setTimeout:setTimeout,clearTimeout:clearTimeout,setInterval:setInterval,clearInterval:clearInterval,Date:Date};a(c,"setImmediate");a(c,"clearImmediate");n.timers=c},{"./core/extend":26,"@sinonjs/commons":47,"@sinonjs/fake-timers":60}],41:[function(e,t,n){var r=e("./prototypes/array").every;function o(e,t){e[t.id]===void 0&&(e[t.id]=0);return e[t.id]<t.callCount}function i(e,t,n,r){var i=true;n!==r.length-1&&(i=t.calledBefore(r[n+1]));if(o(e,t)&&i){e[t.id]+=1;return true}return false}
/**
 * A Sinon proxy object (fake, spy, stub)
 * @typedef {object} SinonProxy
 * @property {Function} calledBefore - A method that determines if this proxy was called before another one
 * @property {string} id - Some id
 * @property {number} callCount - Number of times this proxy has been called
 */
/**
 * Returns true when the spies have been called in the order they were supplied in
 * @param  {SinonProxy[] | SinonProxy} spies An array of proxies, or several proxies as arguments
 * @returns {boolean} true when spies are called in order, false otherwise
 */function s(e){var t={};var n=arguments.length>1?arguments:e;return r(n,i.bind(null,t))}t.exports=s},{"./prototypes/array":49}],42:[function(e,t,n){
/**
 * Returns a display name for a value from a constructor
 * @param  {object} value A value to examine
 * @returns {(string|null)} A string or null
 */
function r(e){const t=e.constructor&&e.constructor.name;return t||null}t.exports=r},{}],43:[function(e,t,n){
/**
 * Returns a function that will invoke the supplied function and print a
 * deprecation warning to the console each time it is called.
 * @param  {Function} func
 * @param  {string} msg
 * @returns {Function}
 */
n.wrap=function(e,t){var r=function(){n.printWarning(t);return e.apply(this,arguments)};e.prototype&&(r.prototype=e.prototype);return r};
/**
 * Returns a string which can be supplied to `wrap()` to notify the user that a
 * particular part of the sinon API has been deprecated.
 * @param  {string} packageName
 * @param  {string} funcName
 * @returns {string}
 */n.defaultMsg=function(e,t){return`${e}.${t} is deprecated and will be removed from the public API in a future version of ${e}.`};
/**
 * Prints a warning on the console, when it exists
 * @param  {string} msg
 * @returns {undefined}
 */n.printWarning=function(e){typeof process==="object"&&process.emitWarning?process.emitWarning(e):console.info?console.info(e):console.log(e)}},{}],44:[function(e,t,n){
/**
 * Returns true when fn returns true for all members of obj.
 * This is an every implementation that works for all iterables
 * @param  {object}   obj
 * @param  {Function} fn
 * @returns {boolean}
 */
t.exports=function(e,t){var n=true;try{e.forEach((function(){if(!t.apply(this,arguments))throw new Error}))}catch(e){n=false}return n}},{}],45:[function(e,t,n){
/**
 * Returns a display name for a function
 * @param  {Function} func
 * @returns {string}
 */
t.exports=function(e){if(!e)return"";try{return e.displayName||e.name||(String(e).match(/function ([^\s(]+)/)||[])[1]}catch(e){return""}}},{}],46:[function(e,t,n){
/**
 * A reference to the global object
 * @type {object} globalObject
 */
var r;r=typeof global!=="undefined"?global:typeof window!=="undefined"?window:self;t.exports=r},{}],47:[function(e,t,n){t.exports={global:e("./global"),calledInOrder:e("./called-in-order"),className:e("./class-name"),deprecated:e("./deprecated"),every:e("./every"),functionName:e("./function-name"),orderByFirstCall:e("./order-by-first-call"),prototypes:e("./prototypes"),typeOf:e("./type-of"),valueToString:e("./value-to-string")}},{"./called-in-order":41,"./class-name":42,"./deprecated":43,"./every":44,"./function-name":45,"./global":46,"./order-by-first-call":48,"./prototypes":52,"./type-of":58,"./value-to-string":59}],48:[function(e,t,n){var r=e("./prototypes/array").sort;var o=e("./prototypes/array").slice;function i(e,t){var n=e.getCall(0);var r=t.getCall(0);var o=n&&n.callId||-1;var i=r&&r.callId||-1;return o<i?-1:1}
/**
 * A Sinon proxy object (fake, spy, stub)
 * @typedef {object} SinonProxy
 * @property {Function} getCall - A method that can return the first call
 */
/**
 * Sorts an array of SinonProxy instances (fake, spy, stub) by their first call
 * @param  {SinonProxy[] | SinonProxy} spies
 * @returns {SinonProxy[]}
 */function s(e){return r(o(e),i)}t.exports=s},{"./prototypes/array":49}],49:[function(e,t,n){var r=e("./copy-prototype-methods");t.exports=r(Array.prototype)},{"./copy-prototype-methods":50}],50:[function(e,t,n){var r=Function.call;var o=e("./throws-on-proto");var i=["size","caller","callee","arguments"];o&&i.push("__proto__");t.exports=function(e){return Object.getOwnPropertyNames(e).reduce((function(t,n){if(i.includes(n))return t;if(typeof e[n]!=="function")return t;t[n]=r.bind(e[n]);return t}),Object.create(null))}},{"./throws-on-proto":57}],51:[function(e,t,n){var r=e("./copy-prototype-methods");t.exports=r(Function.prototype)},{"./copy-prototype-methods":50}],52:[function(e,t,n){t.exports={array:e("./array"),function:e("./function"),map:e("./map"),object:e("./object"),set:e("./set"),string:e("./string")}},{"./array":49,"./function":51,"./map":53,"./object":54,"./set":55,"./string":56}],53:[function(e,t,n){var r=e("./copy-prototype-methods");t.exports=r(Map.prototype)},{"./copy-prototype-methods":50}],54:[function(e,t,n){var r=e("./copy-prototype-methods");t.exports=r(Object.prototype)},{"./copy-prototype-methods":50}],55:[function(e,t,n){var r=e("./copy-prototype-methods");t.exports=r(Set.prototype)},{"./copy-prototype-methods":50}],56:[function(e,t,n){var r=e("./copy-prototype-methods");t.exports=r(String.prototype)},{"./copy-prototype-methods":50}],57:[function(e,t,n){
/**
 * Is true when the environment causes an error to be thrown for accessing the
 * __proto__ property.
 * This is necessary in order to support `node --disable-proto=throw`.
 *
 * See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/proto
 * @type {boolean}
 */
let r;try{const e={};e.__proto__;r=false}catch(e){r=true}t.exports=r},{}],58:[function(e,t,n){var r=e("type-detect");
/**
 * Returns the lower-case result of running type from type-detect on the value
 * @param  {*} value
 * @returns {string}
 */t.exports=function(e){return r(e).toLowerCase()}},{"type-detect":95}],59:[function(e,t,n){
/**
 * Returns a string representation of the value
 * @param  {*} value
 * @returns {string}
 */
function r(e){return e&&e.toString?e.toString():String(e)}t.exports=r},{}],60:[function(e,t,n){const r=e("@sinonjs/commons").global;let o,i;if(typeof e==="function"&&typeof t==="object"){try{o=e("timers")}catch(e){}try{i=e("timers/promises")}catch(e){}}
/**
 * @typedef {object} IdleDeadline
 * @property {boolean} didTimeout - whether or not the callback was called before reaching the optional timeout
 * @property {function():number} timeRemaining - a floating-point value providing an estimate of the number of milliseconds remaining in the current idle period
 */
/**
 * Queues a function to be called during a browser's idle periods
 *
 * @callback RequestIdleCallback
 * @param {function(IdleDeadline)} callback
 * @param {{timeout: number}} options - an options object
 * @returns {number} the id
 */
/**
 * @callback NextTick
 * @param {VoidVarArgsFunc} callback - the callback to run
 * @param {...*} args - optional arguments to call the callback with
 * @returns {void}
 */
/**
 * @callback SetImmediate
 * @param {VoidVarArgsFunc} callback - the callback to run
 * @param {...*} args - optional arguments to call the callback with
 * @returns {NodeImmediate}
 */
/**
 * @callback VoidVarArgsFunc
 * @param {...*} callback - the callback to run
 * @returns {void}
 */
/**
 * @typedef RequestAnimationFrame
 * @property {function(number):void} requestAnimationFrame
 * @returns {number} - the id
 */
/**
 * @typedef Performance
 * @property {function(): number} now
 */
/**
 * @typedef {object} Clock
 * @property {number} now - the current time
 * @property {Date} Date - the Date constructor
 * @property {number} loopLimit - the maximum number of timers before assuming an infinite loop
 * @property {RequestIdleCallback} requestIdleCallback
 * @property {function(number):void} cancelIdleCallback
 * @property {setTimeout} setTimeout
 * @property {clearTimeout} clearTimeout
 * @property {NextTick} nextTick
 * @property {queueMicrotask} queueMicrotask
 * @property {setInterval} setInterval
 * @property {clearInterval} clearInterval
 * @property {SetImmediate} setImmediate
 * @property {function(NodeImmediate):void} clearImmediate
 * @property {function():number} countTimers
 * @property {RequestAnimationFrame} requestAnimationFrame
 * @property {function(number):void} cancelAnimationFrame
 * @property {function():void} runMicrotasks
 * @property {function(string | number): number} tick
 * @property {function(string | number): Promise<number>} tickAsync
 * @property {function(): number} next
 * @property {function(): Promise<number>} nextAsync
 * @property {function(): number} runAll
 * @property {function(): number} runToFrame
 * @property {function(): Promise<number>} runAllAsync
 * @property {function(): number} runToLast
 * @property {function(): Promise<number>} runToLastAsync
 * @property {function(): void} reset
 * @property {function(number | Date): void} setSystemTime
 * @property {function(number): void} jump
 * @property {Performance} performance
 * @property {function(number[]): number[]} hrtime - process.hrtime (legacy)
 * @property {function(): void} uninstall Uninstall the clock.
 * @property {Function[]} methods - the methods that are faked
 * @property {boolean} [shouldClearNativeTimers] inherited from config
 * @property {{methodName:string, original:any}[] | undefined} timersModuleMethods
 * @property {{methodName:string, original:any}[] | undefined} timersPromisesModuleMethods
 * @property {Map<function(): void, AbortSignal>} abortListenerMap
 */
/**
 * Configuration object for the `install` method.
 *
 * @typedef {object} Config
 * @property {number|Date} [now] a number (in milliseconds) or a Date object (default epoch)
 * @property {string[]} [toFake] names of the methods that should be faked.
 * @property {number} [loopLimit] the maximum number of timers that will be run when calling runAll()
 * @property {boolean} [shouldAdvanceTime] tells FakeTimers to increment mocked time automatically (default false)
 * @property {number} [advanceTimeDelta] increment mocked time every <<advanceTimeDelta>> ms (default: 20ms)
 * @property {boolean} [shouldClearNativeTimers] forwards clear timer calls to native functions if they are not fakes (default: false)
 * @property {boolean} [ignoreMissingTimers] default is false, meaning asking to fake timers that are not present will throw an error
 */
/**
 * The internal structure to describe a scheduled fake timer
 *
 * @typedef {object} Timer
 * @property {Function} func
 * @property {*[]} args
 * @property {number} delay
 * @property {number} callAt
 * @property {number} createdAt
 * @property {boolean} immediate
 * @property {number} id
 * @property {Error} [error]
 */
/**
 * A Node timer
 *
 * @typedef {object} NodeImmediate
 * @property {function(): boolean} hasRef
 * @property {function(): NodeImmediate} ref
 * @property {function(): NodeImmediate} unref
 */
/**
 * Mocks available features in the specified global namespace.
 *
 * @param {*} _global Namespace to mock (e.g. `window`)
 * @returns {FakeTimers}
 */function s(t){const n=Math.pow(2,31)-1;const a=1e12;const c=function(){};const l=function(){return[]};const u={};let f,p=false;if(t.setTimeout){u.setTimeout=true;f=t.setTimeout(c,0);p=typeof f==="object"}u.clearTimeout=Boolean(t.clearTimeout);u.setInterval=Boolean(t.setInterval);u.clearInterval=Boolean(t.clearInterval);u.hrtime=t.process&&typeof t.process.hrtime==="function";u.hrtimeBigint=u.hrtime&&typeof t.process.hrtime.bigint==="function";u.nextTick=t.process&&typeof t.process.nextTick==="function";const h=t.process&&e("util").promisify;u.performance=t.performance&&typeof t.performance.now==="function";const d=t.Performance&&(typeof t.Performance).match(/^(function|object)$/);const m=t.performance&&t.performance.constructor&&t.performance.constructor.prototype;u.queueMicrotask=t.hasOwnProperty("queueMicrotask");u.requestAnimationFrame=t.requestAnimationFrame&&typeof t.requestAnimationFrame==="function";u.cancelAnimationFrame=t.cancelAnimationFrame&&typeof t.cancelAnimationFrame==="function";u.requestIdleCallback=t.requestIdleCallback&&typeof t.requestIdleCallback==="function";u.cancelIdleCallbackPresent=t.cancelIdleCallback&&typeof t.cancelIdleCallback==="function";u.setImmediate=t.setImmediate&&typeof t.setImmediate==="function";u.clearImmediate=t.clearImmediate&&typeof t.clearImmediate==="function";u.Intl=t.Intl&&typeof t.Intl==="object";t.clearTimeout&&t.clearTimeout(f);const y=t.Date;const g=t.Intl;let v=a;if(y===void 0)throw new Error("The global scope doesn't have a `Date` object (see https://github.com/sinonjs/sinon/issues/1852#issuecomment-419622780)");u.Date=true;class FakePerformanceEntry{constructor(e,t,n,r){this.name=e;this.entryType=t;this.startTime=n;this.duration=r}toJSON(){return JSON.stringify({...this})}}
/**
     * @param {number} num
     * @returns {boolean}
     */function b(e){return Number.isFinite?Number.isFinite(e):isFinite(e)}let w=false;
/**
     * @param {Clock} clock
     * @param {number} i
     */function x(e,t){e.loopLimit&&t===e.loopLimit-1&&(w=true)}function j(){w=false}
/**
     * Parse strings like "01:10:00" (meaning 1 hour, 10 minutes, 0 seconds) into
     * number of milliseconds. This is used to support human-readable strings passed
     * to clock.tick()
     *
     * @param {string} str
     * @returns {number}
     */function k(e){if(!e)return 0;const t=e.split(":");const n=t.length;let r=n;let o=0;let i;if(n>3||!/^(\d\d:){0,2}\d\d?$/.test(e))throw new Error("tick only understands numbers, 'm:s' and 'h:m:s'. Each part must be two digits");while(r--){i=parseInt(t[r],10);if(i>=60)throw new Error(`Invalid time ${e}`);o+=i*Math.pow(60,n-r-1)}return o*1e3}
/**
     * Get the decimal part of the millisecond value as nanoseconds
     *
     * @param {number} msFloat the number of milliseconds
     * @returns {number} an integer number of nanoseconds in the range [0,1e6)
     *
     * Example: nanoRemainer(123.456789) -> 456789
     */function A(e){const t=1e6;const n=e*1e6%t;const r=n<0?n+t:n;return Math.floor(r)}
/**
     * Used to grok the `now` parameter to createClock.
     *
     * @param {Date|number} epoch the system time
     * @returns {number}
     */function T(e){if(!e)return 0;if(typeof e.getTime==="function")return e.getTime();if(typeof e==="number")return e;throw new TypeError("now should be milliseconds since UNIX epoch")}
/**
     * @param {number} from
     * @param {number} to
     * @param {Timer} timer
     * @returns {boolean}
     */function O(e,t,n){return n&&n.callAt>=e&&n.callAt<=t}
/**
     * @param {Clock} clock
     * @param {Timer} job
     */function C(e,t){const n=new Error(`Aborting after running ${e.loopLimit} timers, assuming an infinite loop!`);if(!t.error)return n;const r=/target\.*[<|(|[].*?[>|\]|)]\s*/;let o=new RegExp(String(Object.keys(e).join("|")));p&&(o=new RegExp(`\\s+at (Object\\.)?(?:${Object.keys(e).join("|")})\\s+`));let i=-1;t.error.stack.split("\n").some((function(e,t){const n=e.match(r);if(n){i=t;return true}const s=e.match(o);if(s){i=t;return false}return i>=0}));const s=`${n}\n${t.type||"Microtask"} - ${t.func.name||"anonymous"}\n${t.error.stack.split("\n").slice(i+1).join("\n")}`;try{Object.defineProperty(n,"stack",{value:s})}catch(e){}return n}function E(){class ClockDate extends y{
/**
             * @param {number} year
             * @param {number} month
             * @param {number} date
             * @param {number} hour
             * @param {number} minute
             * @param {number} second
             * @param {number} ms
             * @returns void
             */
constructor(e,t,n,r,o,i,s){arguments.length===0?super(ClockDate.clock.now):super(...arguments);Object.defineProperty(this,"constructor",{value:y,enumerable:false})}static[Symbol.hasInstance](e){return e instanceof y}}ClockDate.isFake=true;y.now&&(ClockDate.now=function(){return ClockDate.clock.now});y.toSource&&(ClockDate.toSource=function(){return y.toSource()});ClockDate.toString=function(){return y.toString()};
/**
         * A normal Class constructor cannot be called without `new`, but Date can, so we need
         * to wrap it in a Proxy in order to ensure this functionality of Date is kept intact
         *
         * @type {ClockDate}
         */const e=new Proxy(ClockDate,{apply(){if(this instanceof ClockDate)throw new TypeError("A Proxy should only capture `new` calls with the `construct` handler. This is not supposed to be possible, so check the logic.");return new y(ClockDate.clock.now).toString()}});return e}
/**
     * Mirror Intl by default on our fake implementation
     *
     * Most of the properties are the original native ones,
     * but we need to take control of those that have a
     * dependency on the current clock.
     *
     * @returns {object} the partly fake Intl implementation
     */function S(){const e={};Object.getOwnPropertyNames(g).forEach((t=>e[t]=g[t]));e.DateTimeFormat=function(...t){const n=new g.DateTimeFormat(...t);const r={};["formatRange","formatRangeToParts","resolvedOptions"].forEach((e=>{r[e]=n[e].bind(n)}));["format","formatToParts"].forEach((t=>{r[t]=function(r){return n[t](r||e.clock.now)}}));return r};e.DateTimeFormat.prototype=Object.create(g.DateTimeFormat.prototype);e.DateTimeFormat.supportedLocalesOf=g.DateTimeFormat.supportedLocalesOf;return e}function P(e,t){e.jobs||(e.jobs=[]);e.jobs.push(t)}function $(e){if(e.jobs){for(let t=0;t<e.jobs.length;t++){const n=e.jobs[t];n.func.apply(null,n.args);x(e,t);if(e.loopLimit&&t>e.loopLimit)throw C(e,n)}j();e.jobs=[]}}
/**
     * @param {Clock} clock
     * @param {Timer} timer
     * @returns {number} id of the created timer
     */function I(e,t){if(t.func===void 0)throw new Error("Callback must be provided to timer calls");if(p&&typeof t.func!=="function")throw new TypeError(`[ERR_INVALID_CALLBACK]: Callback must be a function. Received ${t.func} of type ${typeof t.func}`);w&&(t.error=new Error);t.type=t.immediate?"Immediate":"Timeout";if(t.hasOwnProperty("delay")){typeof t.delay!=="number"&&(t.delay=parseInt(t.delay,10));b(t.delay)||(t.delay=0);t.delay=t.delay>n?1:t.delay;t.delay=Math.max(0,t.delay)}if(t.hasOwnProperty("interval")){t.type="Interval";t.interval=t.interval>n?1:t.interval}if(t.hasOwnProperty("animation")){t.type="AnimationFrame";t.animation=true}if(t.hasOwnProperty("idleCallback")){t.type="IdleCallback";t.idleCallback=true}e.timers||(e.timers={});t.id=v++;t.createdAt=e.now;t.callAt=e.now+(parseInt(t.delay)||(e.duringTick?1:0));e.timers[t.id]=t;if(p){const n={refed:true,ref:function(){this.refed=true;return n},unref:function(){this.refed=false;return n},hasRef:function(){return this.refed},refresh:function(){t.callAt=e.now+(parseInt(t.delay)||(e.duringTick?1:0));e.timers[t.id]=t;return n},[Symbol.toPrimitive]:function(){return t.id}};return n}return t.id}
/**
     * Timer comparitor
     *
     * @param {Timer} a
     * @param {Timer} b
     * @returns {number}
     */function M(e,t){return e.callAt<t.callAt?-1:e.callAt>t.callAt?1:e.immediate&&!t.immediate?-1:!e.immediate&&t.immediate?1:e.createdAt<t.createdAt?-1:e.createdAt>t.createdAt?1:e.id<t.id?-1:e.id>t.id?1:void 0}
/**
     * @param {Clock} clock
     * @param {number} from
     * @param {number} to
     * @returns {Timer}
     */function F(e,t,n){const r=e.timers;let o=null;let i,s;for(i in r)if(r.hasOwnProperty(i)){s=O(t,n,r[i]);!s||o&&M(o,r[i])!==1||(o=r[i])}return o}
/**
     * @param {Clock} clock
     * @returns {Timer}
     */function L(e){const t=e.timers;let n=null;let r;for(r in t)t.hasOwnProperty(r)&&(n&&M(n,t[r])!==1||(n=t[r]));return n}
/**
     * @param {Clock} clock
     * @returns {Timer}
     */function N(e){const t=e.timers;let n=null;let r;for(r in t)t.hasOwnProperty(r)&&(n&&M(n,t[r])!==-1||(n=t[r]));return n}
/**
     * @param {Clock} clock
     * @param {Timer} timer
     */function D(e,t){typeof t.interval==="number"?e.timers[t.id].callAt+=t.interval:delete e.timers[t.id];if(typeof t.func==="function")t.func.apply(null,t.args);else{const e=eval;(function(){e(t.func)})()}}
/**
     * Gets clear handler name for a given timer type
     *
     * @param {string} ttype
     */function W(e){return e==="IdleCallback"||e==="AnimationFrame"?`cancel${e}`:`clear${e}`}
/**
     * Gets schedule handler name for a given timer type
     *
     * @param {string} ttype
     */function _(e){return e==="IdleCallback"||e==="AnimationFrame"?`request${e}`:`set${e}`}function B(){let e=0;return function(t){!e++&&console.warn(t)}}const z=B();
/**
     * @param {Clock} clock
     * @param {number} timerId
     * @param {string} ttype
     */function q(e,t,n){if(!t)return;e.timers||(e.timers={});const r=Number(t);if(Number.isNaN(r)||r<a){const r=W(n);if(e.shouldClearNativeTimers===true){const n=e[`_${r}`];return typeof n==="function"?n(t):void 0}z(`FakeTimers: ${r} was invoked to clear a native timer instead of one created by this library.\nTo automatically clean-up native timers, use \`shouldClearNativeTimers\`.`)}if(e.timers.hasOwnProperty(r)){const t=e.timers[r];if(!(t.type===n||t.type==="Timeout"&&n==="Interval"||t.type==="Interval"&&n==="Timeout")){const e=W(n);const r=_(t.type);throw new Error(`Cannot clear timer: timer created with ${r}() but cleared with ${e}()`)}delete e.timers[r]}}
/**
     * @param {Clock} clock
     * @param {Config} config
     * @returns {Timer[]}
     */function H(e,n){let r,s,a;const c="_hrtime";const l="_nextTick";for(s=0,a=e.methods.length;s<a;s++){r=e.methods[s];if(r==="hrtime"&&t.process)t.process.hrtime=e[c];else if(r==="nextTick"&&t.process)t.process.nextTick=e[l];else if(r==="performance"){const n=Object.getOwnPropertyDescriptor(e,`_${r}`);n&&n.get&&!n.set?Object.defineProperty(t,r,n):n.configurable&&(t[r]=e[`_${r}`])}else if(t[r]&&t[r].hadOwnProperty)t[r]=e[`_${r}`];else try{delete t[r]}catch(e){}if(e.timersModuleMethods!==void 0)for(let t=0;t<e.timersModuleMethods.length;t++){const n=e.timersModuleMethods[t];o[n.methodName]=n.original}if(e.timersPromisesModuleMethods!==void 0)for(let t=0;t<e.timersPromisesModuleMethods.length;t++){const n=e.timersPromisesModuleMethods[t];i[n.methodName]=n.original}}n.shouldAdvanceTime===true&&t.clearInterval(e.attachedInterval);e.methods=[];for(const[t,n]of e.abortListenerMap.entries()){n.removeEventListener("abort",t);e.abortListenerMap.delete(t)}return e.timers?Object.keys(e.timers).map((function(t){return e.timers[t]})):[]}
/**
     * @param {object} target the target containing the method to replace
     * @param {string} method the keyname of the method on the target
     * @param {Clock} clock
     */function V(e,t,n){n[t].hadOwnProperty=Object.prototype.hasOwnProperty.call(e,t);n[`_${t}`]=e[t];if(t==="Date")e[t]=n[t];else if(t==="Intl")e[t]=n[t];else if(t==="performance"){const r=Object.getOwnPropertyDescriptor(e,t);if(r&&r.get&&!r.set){Object.defineProperty(n,`_${t}`,r);const o=Object.getOwnPropertyDescriptor(n,t);Object.defineProperty(e,t,o)}else e[t]=n[t]}else{e[t]=function(){return n[t].apply(n,arguments)};Object.defineProperties(e[t],Object.getOwnPropertyDescriptors(n[t]))}e[t].clock=n}
/**
     * @param {Clock} clock
     * @param {number} advanceTimeDelta
     */function R(e,t){e.tick(t)}
/**
     * @typedef {object} Timers
     * @property {setTimeout} setTimeout
     * @property {clearTimeout} clearTimeout
     * @property {setInterval} setInterval
     * @property {clearInterval} clearInterval
     * @property {Date} Date
     * @property {Intl} Intl
     * @property {SetImmediate=} setImmediate
     * @property {function(NodeImmediate): void=} clearImmediate
     * @property {function(number[]):number[]=} hrtime
     * @property {NextTick=} nextTick
     * @property {Performance=} performance
     * @property {RequestAnimationFrame=} requestAnimationFrame
     * @property {boolean=} queueMicrotask
     * @property {function(number): void=} cancelAnimationFrame
     * @property {RequestIdleCallback=} requestIdleCallback
     * @property {function(number): void=} cancelIdleCallback
     */
/** @type {Timers} */const U={setTimeout:t.setTimeout,clearTimeout:t.clearTimeout,setInterval:t.setInterval,clearInterval:t.clearInterval,Date:t.Date};u.setImmediate&&(U.setImmediate=t.setImmediate);u.clearImmediate&&(U.clearImmediate=t.clearImmediate);u.hrtime&&(U.hrtime=t.process.hrtime);u.nextTick&&(U.nextTick=t.process.nextTick);u.performance&&(U.performance=t.performance);u.requestAnimationFrame&&(U.requestAnimationFrame=t.requestAnimationFrame);u.queueMicrotask&&(U.queueMicrotask=t.queueMicrotask);u.cancelAnimationFrame&&(U.cancelAnimationFrame=t.cancelAnimationFrame);u.requestIdleCallback&&(U.requestIdleCallback=t.requestIdleCallback);u.cancelIdleCallback&&(U.cancelIdleCallback=t.cancelIdleCallback);u.Intl&&(U.Intl=t.Intl);const J=t.setImmediate||t.setTimeout;
/**
     * @param {Date|number} [start] the system time - non-integer values are floored
     * @param {number} [loopLimit] maximum number of timers that will be run when calling runAll()
     * @returns {Clock}
     */function G(e,n){e=Math.floor(T(e));n=n||1e3;let r=0;const o=[0,0];const i={now:e,Date:E(),loopLimit:n};i.Date.clock=i;function s(){return 16-(i.now-e)%16}function a(t){const n=i.now-o[0]-e;const s=Math.floor(n/1e3);const a=1e6*(n-s*1e3)+r-o[1];if(Array.isArray(t)){if(t[1]>1e9)throw new TypeError("Number of nanoseconds can't exceed a billion");const e=t[0];let n=a-t[1];let r=s-e;if(n<0){n+=1e9;r-=1}return[r,n]}return[s,a]}
/**
         * A high resolution timestamp in milliseconds.
         *
         * @typedef {number} DOMHighResTimeStamp
         */
/**
         * performance.now()
         *
         * @returns {DOMHighResTimeStamp}
         */function c(){const e=a();const t=e[0]*1e3+e[1]/1e6;return t}u.hrtimeBigint&&(a.bigint=function(){const e=a();return BigInt(e[0])*BigInt(1e9)+BigInt(e[1])});if(u.Intl){i.Intl=S();i.Intl.clock=i}i.requestIdleCallback=function(e,t){let n=0;i.countTimers()>0&&(n=50);const r=I(i,{func:e,args:Array.prototype.slice.call(arguments,2),delay:typeof t==="undefined"?n:Math.min(t,n),idleCallback:true});return Number(r)};i.cancelIdleCallback=function(e){return q(i,e,"IdleCallback")};i.setTimeout=function(e,t){return I(i,{func:e,args:Array.prototype.slice.call(arguments,2),delay:t})};typeof t.Promise!=="undefined"&&h&&(i.setTimeout[h.custom]=function(e,n){return new t.Promise((function(t){I(i,{func:t,args:[n],delay:e})}))});i.clearTimeout=function(e){return q(i,e,"Timeout")};i.nextTick=function(e){return P(i,{func:e,args:Array.prototype.slice.call(arguments,1),error:w?new Error:null})};i.queueMicrotask=function(e){return i.nextTick(e)};i.setInterval=function(e,t){t=parseInt(t,10);return I(i,{func:e,args:Array.prototype.slice.call(arguments,2),delay:t,interval:t})};i.clearInterval=function(e){return q(i,e,"Interval")};if(u.setImmediate){i.setImmediate=function(e){return I(i,{func:e,args:Array.prototype.slice.call(arguments,1),immediate:true})};typeof t.Promise!=="undefined"&&h&&(i.setImmediate[h.custom]=function(e){return new t.Promise((function(t){I(i,{func:t,args:[e],immediate:true})}))});i.clearImmediate=function(e){return q(i,e,"Immediate")}}i.countTimers=function(){return Object.keys(i.timers||{}).length+(i.jobs||[]).length};i.requestAnimationFrame=function(e){const t=I(i,{func:e,delay:s(),get args(){return[c()]},animation:true});return Number(t)};i.cancelAnimationFrame=function(e){return q(i,e,"AnimationFrame")};i.runMicrotasks=function(){$(i)};
/**
         * @param {number|string} tickValue milliseconds or a string parseable by parseTime
         * @param {boolean} isAsync
         * @param {Function} resolve
         * @param {Function} reject
         * @returns {number|undefined} will return the new `now` value or nothing for async
         */function l(e,t,n,o){const s=typeof e==="number"?e:k(e);const a=Math.floor(s);const c=A(s);let l=r+c;let u=i.now+a;if(s<0)throw new TypeError("Negative ticks are not supported");if(l>=1e6){u+=1;l-=1e6}r=l;let f=i.now;let p=i.now;let h,d,m,y,g,v;i.duringTick=true;m=i.now;$(i);if(m!==i.now){f+=i.now-m;u+=i.now-m}function b(){h=F(i,f,u);while(h&&f<=u){if(i.timers[h.id]){f=h.callAt;i.now=h.callAt;m=i.now;try{$(i);D(i,h)}catch(e){d=d||e}if(t){J(y);return}g()}v()}m=i.now;$(i);if(m!==i.now){f+=i.now-m;u+=i.now-m}i.duringTick=false;h=F(i,f,u);if(h)try{i.tick(u-i.now)}catch(e){d=d||e}else{i.now=u;r=l}if(d)throw d;if(!t)return i.now;n(i.now)}y=t&&function(){try{g();v();b()}catch(e){o(e)}};g=function(){if(m!==i.now){f+=i.now-m;u+=i.now-m;p+=i.now-m}};v=function(){h=F(i,p,u);p=f};return b()}
/**
         * @param {string|number} tickValue number of milliseconds or a human-readable value like "01:11:15"
         * @returns {number} will return the new `now` value
         */i.tick=function(e){return l(e,false)};typeof t.Promise!=="undefined"&&(
/**
             * @param {string|number} tickValue number of milliseconds or a human-readable value like "01:11:15"
             * @returns {Promise}
             */
i.tickAsync=function(e){return new t.Promise((function(t,n){J((function(){try{l(e,true,t,n)}catch(e){n(e)}}))}))});i.next=function(){$(i);const e=L(i);if(!e)return i.now;i.duringTick=true;try{i.now=e.callAt;D(i,e);$(i);return i.now}finally{i.duringTick=false}};typeof t.Promise!=="undefined"&&(i.nextAsync=function(){return new t.Promise((function(e,t){J((function(){try{const n=L(i);if(!n){e(i.now);return}let r;i.duringTick=true;i.now=n.callAt;try{D(i,n)}catch(e){r=e}i.duringTick=false;J((function(){r?t(r):e(i.now)}))}catch(e){t(e)}}))}))});i.runAll=function(){let e,t;$(i);for(t=0;t<i.loopLimit;t++){if(!i.timers){j();return i.now}e=Object.keys(i.timers).length;if(e===0){j();return i.now}i.next();x(i,t)}const n=L(i);throw C(i,n)};i.runToFrame=function(){return i.tick(s())};typeof t.Promise!=="undefined"&&(i.runAllAsync=function(){return new t.Promise((function(e,t){let n=0;function r(){J((function(){try{$(i);let o;if(n<i.loopLimit){if(!i.timers){j();e(i.now);return}o=Object.keys(i.timers).length;if(o===0){j();e(i.now);return}i.next();n++;r();x(i,n);return}const s=L(i);t(C(i,s))}catch(e){t(e)}}))}r()}))});i.runToLast=function(){const e=N(i);if(!e){$(i);return i.now}return i.tick(e.callAt-i.now)};typeof t.Promise!=="undefined"&&(i.runToLastAsync=function(){return new t.Promise((function(e,t){J((function(){try{const t=N(i);if(!t){$(i);e(i.now)}e(i.tickAsync(t.callAt-i.now))}catch(e){t(e)}}))}))});i.reset=function(){r=0;i.timers={};i.jobs=[];i.now=e};i.setSystemTime=function(e){const t=T(e);const n=t-i.now;let s,a;o[0]=o[0]+n;o[1]=o[1]+r;i.now=t;r=0;for(s in i.timers)if(i.timers.hasOwnProperty(s)){a=i.timers[s];a.createdAt+=n;a.callAt+=n}};
/**
         * @param {string|number} tickValue number of milliseconds or a human-readable value like "01:11:15"
         * @returns {number} will return the new `now` value
         */i.jump=function(e){const t=typeof e==="number"?e:k(e);const n=Math.floor(t);for(const e of Object.values(i.timers))i.now+n>e.callAt&&(e.callAt=i.now+n);i.tick(n)};if(u.performance){i.performance=Object.create(null);i.performance.now=c}u.hrtime&&(i.hrtime=a);return i}
/**
     * @param {Config=} [config] Optional config
     * @returns {Clock}
     */function K(e){if(arguments.length>1||e instanceof Date||Array.isArray(e)||typeof e==="number")throw new TypeError(`FakeTimers.install called with ${String(e)} install requires an object parameter`);if(t.Date.isFake===true)throw new TypeError("Can't install fake timers twice on the same global object.");e=typeof e!=="undefined"?e:{};e.shouldAdvanceTime=e.shouldAdvanceTime||false;e.advanceTimeDelta=e.advanceTimeDelta||20;e.shouldClearNativeTimers=e.shouldClearNativeTimers||false;if(e.target)throw new TypeError("config.target is no longer supported. Use `withGlobal(target)` instead.");
/**
         * @param {string} timer/object the name of the thing that is not present
         * @param timer
         */function n(t){if(!e.ignoreMissingTimers)throw new ReferenceError(`non-existent timers and/or objects cannot be faked: '${t}'`)}let s,a;const f=G(e.now,e.loopLimit);f.shouldClearNativeTimers=e.shouldClearNativeTimers;f.uninstall=function(){return H(f,e)};f.abortListenerMap=new Map;f.methods=e.toFake||[];f.methods.length===0&&(f.methods=Object.keys(U));if(e.shouldAdvanceTime===true){const n=R.bind(null,f,e.advanceTimeDelta);const r=t.setInterval(n,e.advanceTimeDelta);f.attachedInterval=r}if(f.methods.includes("performance")){const r=(()=>m?t.performance.constructor.prototype:d?t.Performance.prototype:void 0)();if(r){Object.getOwnPropertyNames(r).forEach((function(e){e!=="now"&&(f.performance[e]=e.indexOf("getEntries")===0?l:c)}));f.performance.mark=e=>new FakePerformanceEntry(e,"mark",0,0);f.performance.measure=e=>new FakePerformanceEntry(e,"measure",0,100)}else if((e.toFake||[]).includes("performance"))return n("performance")}t===r&&o&&(f.timersModuleMethods=[]);t===r&&i&&(f.timersPromisesModuleMethods=[]);for(s=0,a=f.methods.length;s<a;s++){const e=f.methods[s];if(u[e]){e==="hrtime"?t.process&&typeof t.process.hrtime==="function"&&V(t.process,e,f):e==="nextTick"?t.process&&typeof t.process.nextTick==="function"&&V(t.process,e,f):V(t,e,f);if(f.timersModuleMethods!==void 0&&o[e]){const n=o[e];f.timersModuleMethods.push({methodName:e,original:n});o[e]=t[e]}if(f.timersPromisesModuleMethods!==void 0)if(e==="setTimeout"){f.timersPromisesModuleMethods.push({methodName:"setTimeout",original:i.setTimeout});i.setTimeout=(e,t,n={})=>new Promise(((r,o)=>{const i=()=>{n.signal.removeEventListener("abort",i);f.abortListenerMap.delete(i);f.clearTimeout(s);o(n.signal.reason)};const s=f.setTimeout((()=>{if(n.signal){n.signal.removeEventListener("abort",i);f.abortListenerMap.delete(i)}r(t)}),e);if(n.signal)if(n.signal.aborted)i();else{n.signal.addEventListener("abort",i);f.abortListenerMap.set(i,n.signal)}}))}else if(e==="setImmediate"){f.timersPromisesModuleMethods.push({methodName:"setImmediate",original:i.setImmediate});i.setImmediate=(e,t={})=>new Promise(((n,r)=>{const o=()=>{t.signal.removeEventListener("abort",o);f.abortListenerMap.delete(o);f.clearImmediate(i);r(t.signal.reason)};const i=f.setImmediate((()=>{if(t.signal){t.signal.removeEventListener("abort",o);f.abortListenerMap.delete(o)}n(e)}));if(t.signal)if(t.signal.aborted)o();else{t.signal.addEventListener("abort",o);f.abortListenerMap.set(o,t.signal)}}))}else if(e==="setInterval"){f.timersPromisesModuleMethods.push({methodName:"setInterval",original:i.setInterval});i.setInterval=(e,t,n={})=>({[Symbol.asyncIterator]:()=>{const r=()=>{let e,t;const n=new Promise(((n,r)=>{e=n;t=r}));n.resolve=e;n.reject=t;return n};let o=false;let i=false;let s;let a=0;const c=[];const l=f.setInterval((()=>{c.length>0?c.shift().resolve():a++}),e);const u=()=>{n.signal.removeEventListener("abort",u);f.abortListenerMap.delete(u);f.clearInterval(l);o=true;for(const e of c)e.resolve()};if(n.signal)if(n.signal.aborted)o=true;else{n.signal.addEventListener("abort",u);f.abortListenerMap.set(u,n.signal)}return{next:async()=>{if(n.signal?.aborted&&!i){i=true;throw n.signal.reason}if(o)return{done:true,value:void 0};if(a>0){a--;return{done:false,value:t}}const e=r();c.push(e);await e;s&&c.length===0&&s.resolve();if(n.signal?.aborted&&!i){i=true;throw n.signal.reason}return o?{done:true,value:void 0}:{done:false,value:t}},return:async()=>{if(o)return{done:true,value:void 0};if(c.length>0){s=r();await s}f.clearInterval(l);o=true;if(n.signal){n.signal.removeEventListener("abort",u);f.abortListenerMap.delete(u)}return{done:true,value:void 0}}}}})}}else n(e)}return f}return{timers:U,createClock:G,install:K,withGlobal:s}}
/**
 * @typedef {object} FakeTimers
 * @property {Timers} timers
 * @property {createClock} createClock
 * @property {Function} install
 * @property {withGlobal} withGlobal
 */
/** @type {FakeTimers} */const a=s(r);n.timers=a.timers;n.createClock=a.createClock;n.install=a.install;n.withGlobal=s},{"@sinonjs/commons":47,timers:void 0,"timers/promises":void 0,util:91}],61:[function(e,t,n){var r=[Array,Int8Array,Uint8Array,Uint8ClampedArray,Int16Array,Uint16Array,Int32Array,Uint32Array,Float32Array,Float64Array];t.exports=r},{}],62:[function(e,t,n){var r=e("@sinonjs/commons").prototypes.array;var o=e("./deep-equal").use(k);var i=e("@sinonjs/commons").every;var s=e("@sinonjs/commons").functionName;var a=e("lodash.get");var c=e("./iterable-to-string");var l=e("@sinonjs/commons").prototypes.object;var u=e("@sinonjs/commons").typeOf;var f=e("@sinonjs/commons").valueToString;var p=e("./create-matcher/assert-matcher");var h=e("./create-matcher/assert-method-exists");var d=e("./create-matcher/assert-type");var m=e("./create-matcher/is-iterable");var y=e("./create-matcher/is-matcher");var g=e("./create-matcher/matcher-prototype");var v=r.indexOf;var b=r.some;var w=l.hasOwnProperty;var x=l.toString;var j=e("./create-matcher/type-map")(k);
/**
 * Creates a matcher object for the passed expectation
 *
 * @alias module:samsam.createMatcher
 * @param {*} expectation An expecttation
 * @param {string} message A message for the expectation
 * @returns {object} A matcher object
 */function k(e,t){var n=Object.create(g);var r=u(e);if(t!==void 0&&typeof t!=="string")throw new TypeError("Message should be a string");if(arguments.length>2)throw new TypeError(`Expected 1 or 2 arguments, received ${arguments.length}`);r in j?j[r](n,e,t):n.test=function(t){return o(t,e)};n.message||(n.message=`match(${f(e)})`);Object.defineProperty(n,"message",{configurable:false,writable:false,value:n.message});return n}k.isMatcher=y;k.any=k((function(){return true}),"any");k.defined=k((function(e){return e!==null&&e!==void 0}),"defined");k.truthy=k((function(e){return Boolean(e)}),"truthy");k.falsy=k((function(e){return!e}),"falsy");k.same=function(e){return k((function(t){return e===t}),`same(${f(e)})`)};k.in=function(e){if(u(e)!=="array")throw new TypeError("array expected");return k((function(t){return b(e,(function(e){return e===t}))}),`in(${f(e)})`)};k.typeOf=function(e){d(e,"string","type");return k((function(t){return u(t)===e}),`typeOf("${e}")`)};k.instanceOf=function(e){typeof Symbol==="undefined"||typeof Symbol.hasInstance==="undefined"?d(e,"function","type"):h(e,Symbol.hasInstance,"type","[Symbol.hasInstance]");return k((function(t){return t instanceof e}),`instanceOf(${s(e)||x(e)})`)};
/**
 * Creates a property matcher
 *
 * @private
 * @param {Function} propertyTest A function to test the property against a value
 * @param {string} messagePrefix A prefix to use for messages generated by the matcher
 * @returns {object} A matcher
 */function A(e,t){return function(n,r){d(n,"string","property");var i=arguments.length===1;var s=`${t}("${n}"`;i||(s+=`, ${f(r)}`);s+=")";return k((function(t){return!(t===void 0||t===null||!e(t,n))&&(i||o(t[n],r))}),s)}}k.has=A((function(e,t){return typeof e==="object"?t in e:e[t]!==void 0}),"has");k.hasOwn=A((function(e,t){return w(e,t)}),"hasOwn");k.hasNested=function(e,t){d(e,"string","property");var n=arguments.length===1;var r=`hasNested("${e}"`;n||(r+=`, ${f(t)}`);r+=")";return k((function(r){return r!==void 0&&r!==null&&a(r,e)!==void 0&&(n||o(a(r,e),t))}),r)};var T={null:true,boolean:true,number:true,string:true,object:true,array:true};k.json=function(e){if(!T[u(e)])throw new TypeError("Value cannot be the result of JSON.parse");var t=`json(${JSON.stringify(e,null,"  ")})`;return k((function(t){var n;try{n=JSON.parse(t)}catch(e){return false}return o(n,e)}),t)};k.every=function(e){p(e);return k((function(t){return u(t)==="object"?i(Object.keys(t),(function(n){return e.test(t[n])})):m(t)&&i(t,(function(t){return e.test(t)}))}),`every(${e.message})`)};k.some=function(e){p(e);return k((function(t){return u(t)==="object"?!i(Object.keys(t),(function(n){return!e.test(t[n])})):m(t)&&!i(t,(function(t){return!e.test(t)}))}),`some(${e.message})`)};k.array=k.typeOf("array");k.array.deepEquals=function(e){return k((function(t){var n=t.length===e.length;return u(t)==="array"&&n&&i(t,(function(t,n){var r=e[n];return u(r)==="array"&&u(t)==="array"?k.array.deepEquals(r).test(t):o(r,t)}))}),`deepEquals([${c(e)}])`)};k.array.startsWith=function(e){return k((function(t){return u(t)==="array"&&i(e,(function(e,n){return t[n]===e}))}),`startsWith([${c(e)}])`)};k.array.endsWith=function(e){return k((function(t){var n=t.length-e.length;return u(t)==="array"&&i(e,(function(e,r){return t[n+r]===e}))}),`endsWith([${c(e)}])`)};k.array.contains=function(e){return k((function(t){return u(t)==="array"&&i(e,(function(e){return v(t,e)!==-1}))}),`contains([${c(e)}])`)};k.map=k.typeOf("map");k.map.deepEquals=function(e){return k((function(t){var n=t.size===e.size;return u(t)==="map"&&n&&i(t,(function(t,n){return e.has(n)&&e.get(n)===t}))}),`deepEquals(Map[${c(e)}])`)};k.map.contains=function(e){return k((function(t){return u(t)==="map"&&i(e,(function(e,n){return t.has(n)&&t.get(n)===e}))}),`contains(Map[${c(e)}])`)};k.set=k.typeOf("set");k.set.deepEquals=function(e){return k((function(t){var n=t.size===e.size;return u(t)==="set"&&n&&i(t,(function(t){return e.has(t)}))}),`deepEquals(Set[${c(e)}])`)};k.set.contains=function(e){return k((function(t){return u(t)==="set"&&i(e,(function(e){return t.has(e)}))}),`contains(Set[${c(e)}])`)};k.bool=k.typeOf("boolean");k.number=k.typeOf("number");k.string=k.typeOf("string");k.object=k.typeOf("object");k.func=k.typeOf("function");k.regexp=k.typeOf("regexp");k.date=k.typeOf("date");k.symbol=k.typeOf("symbol");t.exports=k},{"./create-matcher/assert-matcher":63,"./create-matcher/assert-method-exists":64,"./create-matcher/assert-type":65,"./create-matcher/is-iterable":66,"./create-matcher/is-matcher":67,"./create-matcher/matcher-prototype":69,"./create-matcher/type-map":70,"./deep-equal":71,"./iterable-to-string":85,"@sinonjs/commons":47,"lodash.get":93}],63:[function(e,t,n){var r=e("./is-matcher");
/**
 * Throws a TypeError when `value` is not a matcher
 *
 * @private
 * @param {*} value The value to examine
 */function o(e){if(!r(e))throw new TypeError("Matcher expected")}t.exports=o},{"./is-matcher":67}],64:[function(e,t,n){
/**
 * Throws a TypeError when expected method doesn't exist
 *
 * @private
 * @param {*} value A value to examine
 * @param {string} method The name of the method to look for
 * @param {name} name A name to use for the error message
 * @param {string} methodPath The name of the method to use for error messages
 * @throws {TypeError} When the method doesn't exist
 */
function r(e,t,n,r){if(e[t]===null||e[t]===void 0)throw new TypeError(`Expected ${n} to have method ${r}`)}t.exports=r},{}],65:[function(e,t,n){var r=e("@sinonjs/commons").typeOf;
/**
 * Ensures that value is of type
 *
 * @private
 * @param {*} value A value to examine
 * @param {string} type A basic JavaScript type to compare to, e.g. "object", "string"
 * @param {string} name A string to use for the error message
 * @throws {TypeError} If value is not of the expected type
 * @returns {undefined}
 */function o(e,t,n){var o=r(e);if(o!==t)throw new TypeError(`Expected type of ${n} to be ${t}, but was ${o}`)}t.exports=o},{"@sinonjs/commons":47}],66:[function(e,t,n){var r=e("@sinonjs/commons").typeOf;
/**
 * Returns `true` for iterables
 *
 * @private
 * @param {*} value A value to examine
 * @returns {boolean} Returns `true` when `value` looks like an iterable
 */function o(e){return Boolean(e)&&r(e.forEach)==="function"}t.exports=o},{"@sinonjs/commons":47}],67:[function(e,t,n){var r=e("@sinonjs/commons").prototypes.object.isPrototypeOf;var o=e("./matcher-prototype");
/**
 * Returns `true` when `object` is a matcher
 *
 * @private
 * @param {*} object A value to examine
 * @returns {boolean} Returns `true` when `object` is a matcher
 */function i(e){return r(o,e)}t.exports=i},{"./matcher-prototype":69,"@sinonjs/commons":47}],68:[function(e,t,n){var r=e("@sinonjs/commons").prototypes.array.every;var o=e("@sinonjs/commons").prototypes.array.concat;var i=e("@sinonjs/commons").typeOf;var s=e("../deep-equal").use;var a=e("../identical");var c=e("./is-matcher");var l=Object.keys;var u=Object.getOwnPropertySymbols;
/**
 * Matches `actual` with `expectation`
 *
 * @private
 * @param {*} actual A value to examine
 * @param {object} expectation An object with properties to match on
 * @param {object} matcher A matcher to use for comparison
 * @returns {boolean} Returns true when `actual` matches all properties in `expectation`
 */function f(e,t,n){var p=s(n);if(e===null||e===void 0)return false;var h=l(t);i(u)==="function"&&(h=o(h,u(t)));return r(h,(function(r){var o=t[r];var s=e[r];if(c(o)){if(!o.test(s))return false}else if(i(o)==="object"){if(a(o,s))return true;if(!f(s,o,n))return false}else if(!p(s,o))return false;return true}))}t.exports=f},{"../deep-equal":71,"../identical":73,"./is-matcher":67,"@sinonjs/commons":47}],69:[function(e,t,n){var r={toString:function(){return this.message}};r.or=function(t){var n=e("../create-matcher");var o=n.isMatcher;if(!arguments.length)throw new TypeError("Matcher expected");var i=o(t)?t:n(t);var s=this;var a=Object.create(r);a.test=function(e){return s.test(e)||i.test(e)};a.message=`${s.message}.or(${i.message})`;return a};r.and=function(t){var n=e("../create-matcher");var o=n.isMatcher;if(!arguments.length)throw new TypeError("Matcher expected");var i=o(t)?t:n(t);var s=this;var a=Object.create(r);a.test=function(e){return s.test(e)&&i.test(e)};a.message=`${s.message}.and(${i.message})`;return a};t.exports=r},{"../create-matcher":62}],70:[function(e,t,n){var r=e("@sinonjs/commons").functionName;var o=e("@sinonjs/commons").prototypes.array.join;var i=e("@sinonjs/commons").prototypes.array.map;var s=e("@sinonjs/commons").prototypes.string.indexOf;var a=e("@sinonjs/commons").valueToString;var c=e("./match-object");var l=function(e){return{function:function(e,t,n){e.test=t;e.message=n||`match(${r(t)})`},number:function(e,t){e.test=function(e){return t==e}},object:function(t,n){var s=[];if(typeof n.test==="function"){t.test=function(e){return n.test(e)===true};t.message=`match(${r(n.test)})`;return t}s=i(Object.keys(n),(function(e){return`${e}: ${a(n[e])}`}));t.test=function(t){return c(t,n,e)};t.message=`match(${o(s,", ")})`;return t},regexp:function(e,t){e.test=function(e){return typeof e==="string"&&t.test(e)}},string:function(e,t){e.test=function(e){return typeof e==="string"&&s(e,t)!==-1};e.message=`match("${t}")`}}};t.exports=l},{"./match-object":68,"@sinonjs/commons":47}],71:[function(e,t,n){var r=e("@sinonjs/commons").valueToString;var o=e("@sinonjs/commons").className;var i=e("@sinonjs/commons").typeOf;var s=e("@sinonjs/commons").prototypes.array;var a=e("@sinonjs/commons").prototypes.object;var c=e("@sinonjs/commons").prototypes.map.forEach;var l=e("./get-class");var u=e("./identical");var f=e("./is-arguments");var p=e("./is-array-type");var h=e("./is-date");var d=e("./is-element");var m=e("./is-iterable");var y=e("./is-map");var g=e("./is-nan");var v=e("./is-object");var b=e("./is-set");var w=e("./is-subset");var x=s.concat;var j=s.every;var k=s.push;var A=Date.prototype.getTime;var T=a.hasOwnProperty;var O=s.indexOf;var C=Object.keys;var E=Object.getOwnPropertySymbols;
/**
 * Deep equal comparison. Two values are "deep equal" when:
 *
 *   - They are equal, according to samsam.identical
 *   - They are both date objects representing the same time
 *   - They are both arrays containing elements that are all deepEqual
 *   - They are objects with the same set of properties, and each property
 *     in ``actual`` is deepEqual to the corresponding property in ``expectation``
 *
 * Supports cyclic objects.
 *
 * @alias module:samsam.deepEqual
 * @param {*} actual The object to examine
 * @param {*} expectation The object actual is expected to be equal to
 * @param {object} match A value to match on
 * @returns {boolean} Returns true when actual and expectation are considered equal
 */function S(e,t,n){var s=[];var a=[];var P=[];var $=[];var I={};return function e(t,M,F,L){if(n&&n.isMatcher(M))return n.isMatcher(t)?t===M:M.test(t);var N=typeof t;var D=typeof M;if(t===M||g(t)||g(M)||t===null||M===null||t===void 0||M===void 0||N!=="object"||D!=="object")return u(t,M);if(d(t)||d(M))return false;var W=h(t);var _=h(M);if((W||_)&&(!W||!_||A.call(t)!==A.call(M)))return false;if(t instanceof RegExp&&M instanceof RegExp&&r(t)!==r(M))return false;if(t instanceof Promise&&M instanceof Promise)return t===M;if(t instanceof Error&&M instanceof Error)return t===M;var B=l(t);var z=l(M);var q=C(t);var H=C(M);var V=o(t);var R=o(M);var U=i(E)==="function"?E(M):[];var J=x(H,U);if(f(t)||f(M)){if(t.length!==M.length)return false}else if(N!==D||B!==z||q.length!==H.length||V&&R&&V!==R)return false;if(b(t)||b(M))return!(!b(t)||!b(M)||t.size!==M.size)&&w(t,M,e);if(y(t)||y(M)){if(!y(t)||!y(M)||t.size!==M.size)return false;var G=true;c(t,(function(e,t){G=G&&S(e,M.get(t))}));return G}if(t.constructor&&t.constructor.name==="jQuery"&&typeof t.is==="function")return t.is(M);var K=m(t)&&!p(t)&&!f(t);var Q=m(M)&&!p(M)&&!f(M);if(K||Q){var Z=Array.from(t);var X=Array.from(M);if(Z.length!==X.length)return false;var Y=true;j(Z,(function(e){Y=Y&&S(Z[e],X[e])}));return Y}return j(J,(function(n){if(!T(t,n))return false;var r=t[n];var o=M[n];var i=v(r);var c=v(o);var l=i?O(s,r):-1;var u=c?O(a,o):-1;var f=l!==-1?P[l]:`${F}[${JSON.stringify(n)}]`;var p=u!==-1?$[u]:`${L}[${JSON.stringify(n)}]`;var h=f+p;if(I[h])return true;if(l===-1&&i){k(s,r);k(P,f)}if(u===-1&&c){k(a,o);k($,p)}i&&c&&(I[h]=true);return e(r,o,f,p)}))}(e,t,"$1","$2")}S.use=function(e){return function(t,n){return S(t,n,e)}};t.exports=S},{"./get-class":72,"./identical":73,"./is-arguments":74,"./is-array-type":75,"./is-date":76,"./is-element":77,"./is-iterable":78,"./is-map":79,"./is-nan":80,"./is-object":82,"./is-set":83,"./is-subset":84,"@sinonjs/commons":47}],72:[function(e,t,n){var r=e("@sinonjs/commons").prototypes.object.toString;
/**
 * Returns the internal `Class` by calling `Object.prototype.toString`
 * with the provided value as `this`. Return value is a `String`, naming the
 * internal class, e.g. "Array"
 *
 * @private
 * @param  {*} value - Any value
 * @returns {string} - A string representation of the `Class` of `value`
 */function o(e){return r(e).split(/[ \]]/)[1]}t.exports=o},{"@sinonjs/commons":47}],73:[function(e,t,n){var r=e("./is-nan");var o=e("./is-neg-zero");
/**
 * Strict equality check according to EcmaScript Harmony's `egal`.
 *
 * **From the Harmony wiki:**
 * > An `egal` function simply makes available the internal `SameValue` function
 * > from section 9.12 of the ES5 spec. If two values are egal, then they are not
 * > observably distinguishable.
 *
 * `identical` returns `true` when `===` is `true`, except for `-0` and
 * `+0`, where it returns `false`. Additionally, it returns `true` when
 * `NaN` is compared to itself.
 *
 * @alias module:samsam.identical
 * @param {*} obj1 The first value to compare
 * @param {*} obj2 The second value to compare
 * @returns {boolean} Returns `true` when the objects are *egal*, `false` otherwise
 */function i(e,t){return!!(e===t||r(e)&&r(t))&&(e!==0||o(e)===o(t))}t.exports=i},{"./is-nan":80,"./is-neg-zero":81}],74:[function(e,t,n){var r=e("./get-class");
/**
 * Returns `true` when `object` is an `arguments` object, `false` otherwise
 *
 * @alias module:samsam.isArguments
 * @param  {*}  object - The object to examine
 * @returns {boolean} `true` when `object` is an `arguments` object
 */function o(e){return r(e)==="Arguments"}t.exports=o},{"./get-class":72}],75:[function(e,t,n){var r=e("@sinonjs/commons").functionName;var o=e("@sinonjs/commons").prototypes.array.indexOf;var i=e("@sinonjs/commons").prototypes.array.map;var s=e("./array-types");var a=e("type-detect");
/**
 * Returns `true` when `object` is an array type, `false` otherwise
 *
 * @param  {*}  object - The object to examine
 * @returns {boolean} `true` when `object` is an array type
 * @private
 */function c(e){return o(i(s,r),a(e))!==-1}t.exports=c},{"./array-types":61,"@sinonjs/commons":47,"type-detect":88}],76:[function(e,t,n){
/**
 * Returns `true` when `value` is an instance of Date
 *
 * @private
 * @param  {Date}  value The value to examine
 * @returns {boolean}     `true` when `value` is an instance of Date
 */
function r(e){return e instanceof Date}t.exports=r},{}],77:[function(e,t,n){var r=typeof document!=="undefined"&&document.createElement("div");
/**
 * Returns `true` when `object` is a DOM element node.
 *
 * Unlike Underscore.js/lodash, this function will return `false` if `object`
 * is an *element-like* object, i.e. a regular object with a `nodeType`
 * property that holds the value `1`.
 *
 * @alias module:samsam.isElement
 * @param {object} object The object to examine
 * @returns {boolean} Returns `true` for DOM element nodes
 */function o(e){if(!e||e.nodeType!==1||!r)return false;try{e.appendChild(r);e.removeChild(r)}catch(e){return false}return true}t.exports=o},{}],78:[function(e,t,n){
/**
 * Returns `true` when the argument is an iterable, `false` otherwise
 *
 * @alias module:samsam.isIterable
 * @param  {*}  val - A value to examine
 * @returns {boolean} Returns `true` when the argument is an iterable, `false` otherwise
 */
function r(e){return typeof e==="object"&&typeof e[Symbol.iterator]==="function"}t.exports=r},{}],79:[function(e,t,n){
/**
 * Returns `true` when `value` is a Map
 *
 * @param {*} value A value to examine
 * @returns {boolean} `true` when `value` is an instance of `Map`, `false` otherwise
 * @private
 */
function r(e){return typeof Map!=="undefined"&&e instanceof Map}t.exports=r},{}],80:[function(e,t,n){
/**
 * Compares a `value` to `NaN`
 *
 * @private
 * @param {*} value A value to examine
 * @returns {boolean} Returns `true` when `value` is `NaN`
 */
function r(e){return typeof e==="number"&&e!==e}t.exports=r},{}],81:[function(e,t,n){
/**
 * Returns `true` when `value` is `-0`
 *
 * @alias module:samsam.isNegZero
 * @param {*} value A value to examine
 * @returns {boolean} Returns `true` when `value` is `-0`
 */
function r(e){return e===0&&1/e===-Infinity}t.exports=r},{}],82:[function(e,t,n){
/**
 * Returns `true` when the value is a regular Object and not a specialized Object
 *
 * This helps speed up deepEqual cyclic checks
 *
 * The premise is that only Objects are stored in the visited array.
 * So if this function returns false, we don't have to do the
 * expensive operation of searching for the value in the the array of already
 * visited objects
 *
 * @private
 * @param  {object}   value The object to examine
 * @returns {boolean}       `true` when the object is a non-specialised object
 */
function r(e){return typeof e==="object"&&e!==null&&!(e instanceof Boolean)&&!(e instanceof Date)&&!(e instanceof Error)&&!(e instanceof Number)&&!(e instanceof RegExp)&&!(e instanceof String)}t.exports=r},{}],83:[function(e,t,n){
/**
 * Returns `true` when the argument is an instance of Set, `false` otherwise
 *
 * @alias module:samsam.isSet
 * @param  {*}  val - A value to examine
 * @returns {boolean} Returns `true` when the argument is an instance of Set, `false` otherwise
 */
function r(e){return typeof Set!=="undefined"&&e instanceof Set||false}t.exports=r},{}],84:[function(e,t,n){var r=e("@sinonjs/commons").prototypes.set.forEach;
/**
 * Returns `true` when `s1` is a subset of `s2`, `false` otherwise
 *
 * @private
 * @param  {Array|Set}  s1      The target value
 * @param  {Array|Set}  s2      The containing value
 * @param  {Function}  compare A comparison function, should return `true` when
 *                             values are considered equal
 * @returns {boolean} Returns `true` when `s1` is a subset of `s2`, `false`` otherwise
 */function o(e,t,n){var o=true;r(e,(function(e){var i=false;r(t,(function(t){n(t,e)&&(i=true)}));o=o&&i}));return o}t.exports=o},{"@sinonjs/commons":47}],85:[function(e,t,n){var r=e("@sinonjs/commons").prototypes.string.slice;var o=e("@sinonjs/commons").typeOf;var i=e("@sinonjs/commons").valueToString;
/**
 * Creates a string represenation of an iterable object
 *
 * @private
 * @param   {object} obj The iterable object to stringify
 * @returns {string}     A string representation
 */function s(e){return o(e)==="map"?a(e):c(e)}
/**
 * Creates a string representation of a Map
 *
 * @private
 * @param   {Map} map    The map to stringify
 * @returns {string}     A string representation
 */function a(e){var t="";e.forEach((function(e,n){t+=`[${l(n)},${l(e)}],`}));t=r(t,0,-1);return t}
/**
 * Create a string represenation for an iterable
 *
 * @private
 * @param   {object} iterable The iterable to stringify
 * @returns {string}          A string representation
 */function c(e){var t="";e.forEach((function(e){t+=`${l(e)},`}));t=r(t,0,-1);return t}
/**
 * Creates a string representation of the passed `item`
 *
 * @private
 * @param  {object} item The item to stringify
 * @returns {string}      A string representation of `item`
 */function l(e){return typeof e==="string"?`'${e}'`:i(e)}t.exports=s},{"@sinonjs/commons":47}],86:[function(e,t,n){var r=e("@sinonjs/commons").valueToString;var o=e("@sinonjs/commons").prototypes.string.indexOf;var i=e("@sinonjs/commons").prototypes.array.forEach;var s=e("type-detect");var a=typeof Array.from==="function";var c=e("./deep-equal").use(h);var l=e("./is-array-type");var u=e("./is-subset");var f=e("./create-matcher");
/**
 * Returns true when `array` contains all of `subset` as defined by the `compare`
 * argument
 *
 * @param  {Array} array   An array to search for a subset
 * @param  {Array} subset  The subset to find in the array
 * @param  {Function} compare A comparison function
 * @returns {boolean}         [description]
 * @private
 */function p(e,t,n){if(t.length===0)return true;var r,o,i,s;for(r=0,o=e.length;r<o;++r)if(n(e[r],t[0])){for(i=0,s=t.length;i<s;++i){if(r+i>=o)return false;if(!n(e[r+i],t[i]))return false}return true}return false}
/**
 * Matches an object with a matcher (or value)
 *
 * @alias module:samsam.match
 * @param {object} object The object candidate to match
 * @param {object} matcherOrValue A matcher or value to match against
 * @returns {boolean} true when `object` matches `matcherOrValue`
 */function h(e,t){if(t&&typeof t.test==="function")return t.test(e);switch(s(t)){case"bigint":case"boolean":case"number":case"symbol":return t===e;case"function":return t(e)===true;case"string":var n=typeof e==="string"||Boolean(e);return n&&o(r(e).toLowerCase(),t.toLowerCase())>=0;case"null":return e===null;case"undefined":return typeof e==="undefined";case"Date":if(s(e)==="Date")return e.getTime()===t.getTime();break;case"Array":case"Int8Array":case"Uint8Array":case"Uint8ClampedArray":case"Int16Array":case"Uint16Array":case"Int32Array":case"Uint32Array":case"Float32Array":case"Float64Array":return l(t)&&p(e,t,h);case"Map":if(!a)throw new Error("The JavaScript engine does not support Array.from and cannot reliably do value comparison of Map instances");return s(e)==="Map"&&p(Array.from(e),Array.from(t),h);default:break}switch(s(e)){case"null":return false;case"Set":return u(t,e,h);default:break}if(t&&typeof t==="object"){if(t===e)return true;if(typeof e!=="object")return false;var i;for(i in t){var f=e[i];typeof f==="undefined"&&typeof e.getAttribute==="function"&&(f=e.getAttribute(i));if(t[i]===null||typeof t[i]==="undefined"){if(f!==t[i])return false}else if(typeof f==="undefined"||!c(f,t[i]))return false}return true}throw new Error("Matcher was an unknown or unsupported type")}i(Object.keys(f),(function(e){h[e]=f[e]}));t.exports=h},{"./create-matcher":62,"./deep-equal":71,"./is-array-type":75,"./is-subset":84,"@sinonjs/commons":47,"type-detect":88}],87:[function(e,t,n){var r=e("./identical");var o=e("./is-arguments");var i=e("./is-element");var s=e("./is-neg-zero");var a=e("./is-set");var c=e("./is-map");var l=e("./match");var u=e("./deep-equal").use(l);var f=e("./create-matcher");t.exports={createMatcher:f,deepEqual:u,identical:r,isArguments:o,isElement:i,isMap:c,isNegZero:s,isSet:a,match:l}},{"./create-matcher":62,"./deep-equal":71,"./identical":73,"./is-arguments":74,"./is-element":77,"./is-map":79,"./is-neg-zero":81,"./is-set":83,"./match":86}],88:[function(e,t,n){(function(e,r){typeof n==="object"&&typeof t!=="undefined"?t.exports=r():typeof define==="function"&&define.amd?define(r):(e=typeof globalThis!=="undefined"?globalThis:e||self,e.typeDetect=r())})(this,(function(){var e=typeof Promise==="function";var t=function(e){if(typeof globalThis==="object")return globalThis;Object.defineProperty(e,"typeDetectGlobalObject",{get:function(){return this},configurable:true});var t=typeDetectGlobalObject;delete e.typeDetectGlobalObject;return t}(Object.prototype);var n=typeof Symbol!=="undefined";var r=typeof Map!=="undefined";var o=typeof Set!=="undefined";var i=typeof WeakMap!=="undefined";var s=typeof WeakSet!=="undefined";var a=typeof DataView!=="undefined";var c=n&&typeof Symbol.iterator!=="undefined";var l=n&&typeof Symbol.toStringTag!=="undefined";var u=o&&typeof Set.prototype.entries==="function";var f=r&&typeof Map.prototype.entries==="function";var p=u&&Object.getPrototypeOf((new Set).entries());var h=f&&Object.getPrototypeOf((new Map).entries());var d=c&&typeof Array.prototype[Symbol.iterator]==="function";var m=d&&Object.getPrototypeOf([][Symbol.iterator]());var y=c&&typeof String.prototype[Symbol.iterator]==="function";var g=y&&Object.getPrototypeOf(""[Symbol.iterator]());var v=8;var b=-1;function w(n){var c=typeof n;if(c!=="object")return c;if(n===null)return"null";if(n===t)return"global";if(Array.isArray(n)&&(l===false||!(Symbol.toStringTag in n)))return"Array";if(typeof window==="object"&&window!==null){if(typeof window.location==="object"&&n===window.location)return"Location";if(typeof window.document==="object"&&n===window.document)return"Document";if(typeof window.navigator==="object"){if(typeof window.navigator.mimeTypes==="object"&&n===window.navigator.mimeTypes)return"MimeTypeArray";if(typeof window.navigator.plugins==="object"&&n===window.navigator.plugins)return"PluginArray"}if((typeof window.HTMLElement==="function"||typeof window.HTMLElement==="object")&&n instanceof window.HTMLElement){if(n.tagName==="BLOCKQUOTE")return"HTMLQuoteElement";if(n.tagName==="TD")return"HTMLTableDataCellElement";if(n.tagName==="TH")return"HTMLTableHeaderCellElement"}}var u=l&&n[Symbol.toStringTag];if(typeof u==="string")return u;var f=Object.getPrototypeOf(n);return f===RegExp.prototype?"RegExp":f===Date.prototype?"Date":e&&f===Promise.prototype?"Promise":o&&f===Set.prototype?"Set":r&&f===Map.prototype?"Map":s&&f===WeakSet.prototype?"WeakSet":i&&f===WeakMap.prototype?"WeakMap":a&&f===DataView.prototype?"DataView":r&&f===h?"Map Iterator":o&&f===p?"Set Iterator":d&&f===m?"Array Iterator":y&&f===g?"String Iterator":f===null?"Object":Object.prototype.toString.call(n).slice(v,b)}return w}))},{}],89:[function(e,t,n){typeof Object.create==="function"?t.exports=function(e,t){e.super_=t;e.prototype=Object.create(t.prototype,{constructor:{value:e,enumerable:false,writable:true,configurable:true}})}:t.exports=function(e,t){e.super_=t;var n=function(){};n.prototype=t.prototype;e.prototype=new n;e.prototype.constructor=e}},{}],90:[function(e,t,n){t.exports=function(e){return e&&typeof e==="object"&&typeof e.copy==="function"&&typeof e.fill==="function"&&typeof e.readUInt8==="function"}},{}],91:[function(e,t,n){var r=/%[sdj%]/g;n.format=function(e){if(!x(e)){var t=[];for(var n=0;n<arguments.length;n++)t.push(s(arguments[n]));return t.join(" ")}n=1;var o=arguments;var i=o.length;var a=String(e).replace(r,(function(e){if(e==="%%")return"%";if(n>=i)return e;switch(e){case"%s":return String(o[n++]);case"%d":return Number(o[n++]);case"%j":try{return JSON.stringify(o[n++])}catch(e){return"[Circular]"}default:return e}}));for(var c=o[n];n<i;c=o[++n])v(c)||!T(c)?a+=" "+c:a+=" "+s(c);return a};n.deprecate=function(e,t){if(k(global.process))return function(){return n.deprecate(e,t).apply(this,arguments)};if(process.noDeprecation===true)return e;var r=false;function o(){if(!r){if(process.throwDeprecation)throw new Error(t);process.traceDeprecation?console.trace(t):console.error(t);r=true}return e.apply(this,arguments)}return o};var o={};var i;n.debuglog=function(e){k(i)&&(i=process.env.NODE_DEBUG||"");e=e.toUpperCase();if(!o[e])if(new RegExp("\\b"+e+"\\b","i").test(i)){var t=process.pid;o[e]=function(){var r=n.format.apply(n,arguments);console.error("%s %d: %s",e,t,r)}}else o[e]=function(){};return o[e]};
/**
 * Echos the value of a value. Trys to print the value out
 * in the best way possible given the different types.
 *
 * @param {Object} obj The object to print out.
 * @param {Object} opts Optional options object that alters the output.
 */function s(e,t){var r={seen:[],stylize:c};arguments.length>=3&&(r.depth=arguments[2]);arguments.length>=4&&(r.colors=arguments[3]);g(t)?r.showHidden=t:t&&n._extend(r,t);k(r.showHidden)&&(r.showHidden=false);k(r.depth)&&(r.depth=2);k(r.colors)&&(r.colors=false);k(r.customInspect)&&(r.customInspect=true);r.colors&&(r.stylize=a);return u(r,e,r.depth)}n.inspect=s;s.colors={bold:[1,22],italic:[3,23],underline:[4,24],inverse:[7,27],white:[37,39],grey:[90,39],black:[30,39],blue:[34,39],cyan:[36,39],green:[32,39],magenta:[35,39],red:[31,39],yellow:[33,39]};s.styles={special:"cyan",number:"yellow",boolean:"yellow",undefined:"grey",null:"bold",string:"green",date:"magenta",regexp:"red"};function a(e,t){var n=s.styles[t];return n?"["+s.colors[n][0]+"m"+e+"["+s.colors[n][1]+"m":e}function c(e,t){return e}function l(e){var t={};e.forEach((function(e,n){t[e]=true}));return t}function u(e,t,r){if(e.customInspect&&t&&E(t.inspect)&&t.inspect!==n.inspect&&!(t.constructor&&t.constructor.prototype===t)){var o=t.inspect(r,e);x(o)||(o=u(e,o,r));return o}var i=f(e,t);if(i)return i;var s=Object.keys(t);var a=l(s);e.showHidden&&(s=Object.getOwnPropertyNames(t));if(C(t)&&(s.indexOf("message")>=0||s.indexOf("description")>=0))return p(t);if(s.length===0){if(E(t)){var c=t.name?": "+t.name:"";return e.stylize("[Function"+c+"]","special")}if(A(t))return e.stylize(RegExp.prototype.toString.call(t),"regexp");if(O(t))return e.stylize(Date.prototype.toString.call(t),"date");if(C(t))return p(t)}var g="",v=false,b=["{","}"];if(y(t)){v=true;b=["[","]"]}if(E(t)){var w=t.name?": "+t.name:"";g=" [Function"+w+"]"}A(t)&&(g=" "+RegExp.prototype.toString.call(t));O(t)&&(g=" "+Date.prototype.toUTCString.call(t));C(t)&&(g=" "+p(t));if(s.length===0&&(!v||t.length==0))return b[0]+g+b[1];if(r<0)return A(t)?e.stylize(RegExp.prototype.toString.call(t),"regexp"):e.stylize("[Object]","special");e.seen.push(t);var j;j=v?h(e,t,r,a,s):s.map((function(n){return d(e,t,r,a,n,v)}));e.seen.pop();return m(j,g,b)}function f(e,t){if(k(t))return e.stylize("undefined","undefined");if(x(t)){var n="'"+JSON.stringify(t).replace(/^"|"$/g,"").replace(/'/g,"\\'").replace(/\\"/g,'"')+"'";return e.stylize(n,"string")}return w(t)?e.stylize(""+t,"number"):g(t)?e.stylize(""+t,"boolean"):v(t)?e.stylize("null","null"):void 0}function p(e){return"["+Error.prototype.toString.call(e)+"]"}function h(e,t,n,r,o){var i=[];for(var s=0,a=t.length;s<a;++s)F(t,String(s))?i.push(d(e,t,n,r,String(s),true)):i.push("");o.forEach((function(o){o.match(/^\d+$/)||i.push(d(e,t,n,r,o,true))}));return i}function d(e,t,n,r,o,i){var s,a,c;c=Object.getOwnPropertyDescriptor(t,o)||{value:t[o]};c.get?a=c.set?e.stylize("[Getter/Setter]","special"):e.stylize("[Getter]","special"):c.set&&(a=e.stylize("[Setter]","special"));F(r,o)||(s="["+o+"]");if(!a)if(e.seen.indexOf(c.value)<0){a=v(n)?u(e,c.value,null):u(e,c.value,n-1);a.indexOf("\n")>-1&&(a=i?a.split("\n").map((function(e){return"  "+e})).join("\n").substr(2):"\n"+a.split("\n").map((function(e){return"   "+e})).join("\n"))}else a=e.stylize("[Circular]","special");if(k(s)){if(i&&o.match(/^\d+$/))return a;s=JSON.stringify(""+o);if(s.match(/^"([a-zA-Z_][a-zA-Z_0-9]*)"$/)){s=s.substr(1,s.length-2);s=e.stylize(s,"name")}else{s=s.replace(/'/g,"\\'").replace(/\\"/g,'"').replace(/(^"|"$)/g,"'");s=e.stylize(s,"string")}}return s+": "+a}function m(e,t,n){var r=0;var o=e.reduce((function(e,t){r++;t.indexOf("\n")>=0&&r++;return e+t.replace(/\u001b\[\d\d?m/g,"").length+1}),0);return o>60?n[0]+(t===""?"":t+"\n ")+" "+e.join(",\n  ")+" "+n[1]:n[0]+t+" "+e.join(", ")+" "+n[1]}function y(e){return Array.isArray(e)}n.isArray=y;function g(e){return typeof e==="boolean"}n.isBoolean=g;function v(e){return e===null}n.isNull=v;function b(e){return e==null}n.isNullOrUndefined=b;function w(e){return typeof e==="number"}n.isNumber=w;function x(e){return typeof e==="string"}n.isString=x;function j(e){return typeof e==="symbol"}n.isSymbol=j;function k(e){return e===void 0}n.isUndefined=k;function A(e){return T(e)&&P(e)==="[object RegExp]"}n.isRegExp=A;function T(e){return typeof e==="object"&&e!==null}n.isObject=T;function O(e){return T(e)&&P(e)==="[object Date]"}n.isDate=O;function C(e){return T(e)&&(P(e)==="[object Error]"||e instanceof Error)}n.isError=C;function E(e){return typeof e==="function"}n.isFunction=E;function S(e){return e===null||typeof e==="boolean"||typeof e==="number"||typeof e==="string"||typeof e==="symbol"||typeof e==="undefined"}n.isPrimitive=S;n.isBuffer=e("./support/isBuffer");function P(e){return Object.prototype.toString.call(e)}function $(e){return e<10?"0"+e.toString(10):e.toString(10)}var I=["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];function M(){var e=new Date;var t=[$(e.getHours()),$(e.getMinutes()),$(e.getSeconds())].join(":");return[e.getDate(),I[e.getMonth()],t].join(" ")}n.log=function(){console.log("%s - %s",M(),n.format.apply(n,arguments))};
/**
 * Inherit the prototype methods from one constructor into another.
 *
 * The Function.prototype.inherits from lang.js rewritten as a standalone
 * function (not on Function.prototype). NOTE: If this file is to be loaded
 * during bootstrapping this function needs to be rewritten using some native
 * functions as prototype setup using normal JavaScript does not work as
 * expected during bootstrapping (see mirror.js in r114903).
 *
 * @param {function} ctor Constructor function which needs to inherit the
 *     prototype.
 * @param {function} superCtor Constructor function to inherit prototype from.
 */n.inherits=e("inherits");n._extend=function(e,t){if(!t||!T(t))return e;var n=Object.keys(t);var r=n.length;while(r--)e[n[r]]=t[n[r]];return e};function F(e,t){return Object.prototype.hasOwnProperty.call(e,t)}},{"./support/isBuffer":90,inherits:89}],92:[function(e,t,n){
/*!

 diff v7.0.0

BSD 3-Clause License

Copyright (c) 2009-2015, Kevin Decker <kpdecker@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@license
*/
(function(e,r){typeof n==="object"&&typeof t!=="undefined"?r(n):typeof define==="function"&&define.amd?define(["exports"],r):(e=typeof globalThis!=="undefined"?globalThis:e||self,r(e.Diff={}))})(this,(function(e){function t(){}t.prototype={diff:function(e,t){var r;var o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};var i=o.callback;if(typeof o==="function"){i=o;o={}}var s=this;function a(e){e=s.postProcess(e,o);if(i){setTimeout((function(){i(e)}),0);return true}return e}e=this.castInput(e,o);t=this.castInput(t,o);e=this.removeEmpty(this.tokenize(e,o));t=this.removeEmpty(this.tokenize(t,o));var c=t.length,l=e.length;var u=1;var f=c+l;o.maxEditLength!=null&&(f=Math.min(f,o.maxEditLength));var p=(r=o.timeout)!==null&&r!==void 0?r:Infinity;var h=Date.now()+p;var d=[{oldPos:-1,lastComponent:void 0}];var m=this.extractCommon(d[0],t,e,0,o);if(d[0].oldPos+1>=l&&m+1>=c)return a(n(s,d[0].lastComponent,t,e,s.useLongestToken));var y=-Infinity,g=Infinity;function v(){for(var r=Math.max(y,-u);r<=Math.min(g,u);r+=2){var i=void 0;var f=d[r-1],p=d[r+1];f&&(d[r-1]=void 0);var h=false;if(p){var v=p.oldPos-r;h=p&&0<=v&&v<c}var b=f&&f.oldPos+1<l;if(h||b){i=!b||h&&f.oldPos<p.oldPos?s.addToPath(p,true,false,0,o):s.addToPath(f,false,true,1,o);m=s.extractCommon(i,t,e,r,o);if(i.oldPos+1>=l&&m+1>=c)return a(n(s,i.lastComponent,t,e,s.useLongestToken));d[r]=i;i.oldPos+1>=l&&(g=Math.min(g,r-1));m+1>=c&&(y=Math.max(y,r+1))}else d[r]=void 0}u++}if(i)(function e(){setTimeout((function(){if(u>f||Date.now()>h)return i();v()||e()}),0)})();else while(u<=f&&Date.now()<=h){var b=v();if(b)return b}},addToPath:function(e,t,n,r,o){var i=e.lastComponent;return i&&!o.oneChangePerToken&&i.added===t&&i.removed===n?{oldPos:e.oldPos+r,lastComponent:{count:i.count+1,added:t,removed:n,previousComponent:i.previousComponent}}:{oldPos:e.oldPos+r,lastComponent:{count:1,added:t,removed:n,previousComponent:i}}},extractCommon:function(e,t,n,r,o){var i=t.length,s=n.length,a=e.oldPos,c=a-r,l=0;while(c+1<i&&a+1<s&&this.equals(n[a+1],t[c+1],o)){c++;a++;l++;o.oneChangePerToken&&(e.lastComponent={count:1,previousComponent:e.lastComponent,added:false,removed:false})}l&&!o.oneChangePerToken&&(e.lastComponent={count:l,previousComponent:e.lastComponent,added:false,removed:false});e.oldPos=a;return c},equals:function(e,t,n){return n.comparator?n.comparator(e,t):e===t||n.ignoreCase&&e.toLowerCase()===t.toLowerCase()},removeEmpty:function(e){var t=[];for(var n=0;n<e.length;n++)e[n]&&t.push(e[n]);return t},castInput:function(e){return e},tokenize:function(e){return Array.from(e)},join:function(e){return e.join("")},postProcess:function(e){return e}};function n(e,t,n,r,o){var i=[];var s;while(t){i.push(t);s=t.previousComponent;delete t.previousComponent;t=s}i.reverse();var a=0,c=i.length,l=0,u=0;for(;a<c;a++){var f=i[a];if(f.removed){f.value=e.join(r.slice(u,u+f.count));u+=f.count}else{if(!f.added&&o){var p=n.slice(l,l+f.count);p=p.map((function(e,t){var n=r[u+t];return n.length>e.length?n:e}));f.value=e.join(p)}else f.value=e.join(n.slice(l,l+f.count));l+=f.count;f.added||(u+=f.count)}}return i}var r=new t;function o(e,t,n){return r.diff(e,t,n)}function i(e,t){var n;for(n=0;n<e.length&&n<t.length;n++)if(e[n]!=t[n])return e.slice(0,n);return e.slice(0,n)}function s(e,t){var n;if(!e||!t||e[e.length-1]!=t[t.length-1])return"";for(n=0;n<e.length&&n<t.length;n++)if(e[e.length-(n+1)]!=t[t.length-(n+1)])return e.slice(-n);return e.slice(-n)}function a(e,t,n){if(e.slice(0,t.length)!=t)throw Error("string ".concat(JSON.stringify(e)," doesn't start with prefix ").concat(JSON.stringify(t),"; this is a bug"));return n+e.slice(t.length)}function c(e,t,n){if(!t)return e+n;if(e.slice(-t.length)!=t)throw Error("string ".concat(JSON.stringify(e)," doesn't end with suffix ").concat(JSON.stringify(t),"; this is a bug"));return e.slice(0,-t.length)+n}function l(e,t){return a(e,t,"")}function u(e,t){return c(e,t,"")}function f(e,t){return t.slice(0,p(e,t))}function p(e,t){var n=0;e.length>t.length&&(n=e.length-t.length);var r=t.length;e.length<t.length&&(r=e.length);var o=Array(r);var i=0;o[0]=0;for(var s=1;s<r;s++){t[s]==t[i]?o[s]=o[i]:o[s]=i;while(i>0&&t[s]!=t[i])i=o[i];t[s]==t[i]&&i++}i=0;for(var a=n;a<e.length;a++){while(i>0&&e[a]!=t[i])i=o[i];e[a]==t[i]&&i++}return i}function h(e){return e.includes("\r\n")&&!e.startsWith("\n")&&!e.match(/[^\r]\n/)}function d(e){return!e.includes("\r\n")&&e.includes("\n")}var m="a-zA-Z0-9_\\u{C0}-\\u{FF}\\u{D8}-\\u{F6}\\u{F8}-\\u{2C6}\\u{2C8}-\\u{2D7}\\u{2DE}-\\u{2FF}\\u{1E00}-\\u{1EFF}";var y=new RegExp("[".concat(m,"]+|\\s+|[^").concat(m,"]"),"ug");var g=new t;g.equals=function(e,t,n){if(n.ignoreCase){e=e.toLowerCase();t=t.toLowerCase()}return e.trim()===t.trim()};g.tokenize=function(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};var n;if(t.intlSegmenter){if(t.intlSegmenter.resolvedOptions().granularity!="word")throw new Error('The segmenter passed must have a granularity of "word"');n=Array.from(t.intlSegmenter.segment(e),(function(e){return e.segment}))}else n=e.match(y)||[];var r=[];var o=null;n.forEach((function(e){/\s/.test(e)?o==null?r.push(e):r.push(r.pop()+e):/\s/.test(o)?r[r.length-1]==o?r.push(r.pop()+e):r.push(o+e):r.push(e);o=e}));return r};g.join=function(e){return e.map((function(e,t){return t==0?e:e.replace(/^\s+/,"")})).join("")};g.postProcess=function(e,t){if(!e||t.oneChangePerToken)return e;var n=null;var r=null;var o=null;e.forEach((function(e){if(e.added)r=e;else if(e.removed)o=e;else{(r||o)&&b(n,o,r,e);n=e;r=null;o=null}}));(r||o)&&b(n,o,r,null);return e};function v(e,t,n){return(n===null||n===void 0?void 0:n.ignoreWhitespace)==null||n.ignoreWhitespace?g.diff(e,t,n):x(e,t,n)}function b(e,t,n,r){if(t&&n){var o=t.value.match(/^\s*/)[0];var p=t.value.match(/\s*$/)[0];var h=n.value.match(/^\s*/)[0];var d=n.value.match(/\s*$/)[0];if(e){var m=i(o,h);e.value=c(e.value,h,m);t.value=l(t.value,m);n.value=l(n.value,m)}if(r){var y=s(p,d);r.value=a(r.value,d,y);t.value=u(t.value,y);n.value=u(n.value,y)}}else if(n){e&&(n.value=n.value.replace(/^\s*/,""));r&&(r.value=r.value.replace(/^\s*/,""))}else if(e&&r){var g=r.value.match(/^\s*/)[0],v=t.value.match(/^\s*/)[0],b=t.value.match(/\s*$/)[0];var w=i(g,v);t.value=l(t.value,w);var x=s(l(g,w),b);t.value=u(t.value,x);r.value=a(r.value,g,x);e.value=c(e.value,g,g.slice(0,g.length-x.length))}else if(r){var j=r.value.match(/^\s*/)[0];var k=t.value.match(/\s*$/)[0];var A=f(k,j);t.value=u(t.value,A)}else if(e){var T=e.value.match(/\s*$/)[0];var O=t.value.match(/^\s*/)[0];var C=f(T,O);t.value=l(t.value,C)}}var w=new t;w.tokenize=function(e){var t=new RegExp("(\\r?\\n)|[".concat(m,"]+|[^\\S\\n\\r]+|[^").concat(m,"]"),"ug");return e.match(t)||[]};function x(e,t,n){return w.diff(e,t,n)}function j(e,t){if(typeof e==="function")t.callback=e;else if(e)for(var n in e)e.hasOwnProperty(n)&&(t[n]=e[n]);return t}var k=new t;k.tokenize=function(e,t){t.stripTrailingCr&&(e=e.replace(/\r\n/g,"\n"));var n=[],r=e.split(/(\n|\r\n)/);r[r.length-1]||r.pop();for(var o=0;o<r.length;o++){var i=r[o];o%2&&!t.newlineIsToken?n[n.length-1]+=i:n.push(i)}return n};k.equals=function(e,n,r){if(r.ignoreWhitespace){r.newlineIsToken&&e.includes("\n")||(e=e.trim());r.newlineIsToken&&n.includes("\n")||(n=n.trim())}else if(r.ignoreNewlineAtEof&&!r.newlineIsToken){e.endsWith("\n")&&(e=e.slice(0,-1));n.endsWith("\n")&&(n=n.slice(0,-1))}return t.prototype.equals.call(this,e,n,r)};function A(e,t,n){return k.diff(e,t,n)}function T(e,t,n){var r=j(n,{ignoreWhitespace:true});return k.diff(e,t,r)}var O=new t;O.tokenize=function(e){return e.split(/(\S.+?[.!?])(?=\s+|$)/)};function C(e,t,n){return O.diff(e,t,n)}var E=new t;E.tokenize=function(e){return e.split(/([{}:;,]|\s+)/)};function S(e,t,n){return E.diff(e,t,n)}function P(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function $(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?P(Object(n),!0).forEach((function(t){L(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):P(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function I(e,t){if("object"!=typeof e||!e)return e;var n=e[Symbol.toPrimitive];if(void 0!==n){var r=n.call(e,t||"default");if("object"!=typeof r)return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===t?String:Number)(e)}function M(e){var t=I(e,"string");return"symbol"==typeof t?t:t+""}function F(e){return F="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},F(e)}function L(e,t,n){t=M(t);t in e?Object.defineProperty(e,t,{value:n,enumerable:true,configurable:true,writable:true}):e[t]=n;return e}function N(e){return D(e)||W(e)||_(e)||z()}function D(e){if(Array.isArray(e))return B(e)}function W(e){if(typeof Symbol!=="undefined"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function _(e,t){if(e){if(typeof e==="string")return B(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);n==="Object"&&e.constructor&&(n=e.constructor.name);return n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?B(e,t):void 0}}function B(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function z(){throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}var q=new t;q.useLongestToken=true;q.tokenize=k.tokenize;q.castInput=function(e,t){var n=t.undefinedReplacement,r=t.stringifyReplacer,o=r===void 0?function(e,t){return typeof t==="undefined"?n:t}:r;return typeof e==="string"?e:JSON.stringify(V(e,null,null,o),o,"  ")};q.equals=function(e,n,r){return t.prototype.equals.call(q,e.replace(/,([\r\n])/g,"$1"),n.replace(/,([\r\n])/g,"$1"),r)};function H(e,t,n){return q.diff(e,t,n)}function V(e,t,n,r,o){t=t||[];n=n||[];r&&(e=r(o,e));var i;for(i=0;i<t.length;i+=1)if(t[i]===e)return n[i];var s;if("[object Array]"===Object.prototype.toString.call(e)){t.push(e);s=new Array(e.length);n.push(s);for(i=0;i<e.length;i+=1)s[i]=V(e[i],t,n,r,o);t.pop();n.pop();return s}e&&e.toJSON&&(e=e.toJSON());if(F(e)==="object"&&e!==null){t.push(e);s={};n.push(s);var a,c=[];for(a in e)Object.prototype.hasOwnProperty.call(e,a)&&c.push(a);c.sort();for(i=0;i<c.length;i+=1){a=c[i];s[a]=V(e[a],t,n,r,a)}t.pop();n.pop()}else s=e;return s}var R=new t;R.tokenize=function(e){return e.slice()};R.join=R.removeEmpty=function(e){return e};function U(e,t,n){return R.diff(e,t,n)}function J(e){return Array.isArray(e)?e.map(J):$($({},e),{},{hunks:e.hunks.map((function(e){return $($({},e),{},{lines:e.lines.map((function(t,n){var r;return t.startsWith("\\")||t.endsWith("\r")||(r=e.lines[n+1])!==null&&r!==void 0&&r.startsWith("\\")?t:t+"\r"}))})}))})}function G(e){return Array.isArray(e)?e.map(G):$($({},e),{},{hunks:e.hunks.map((function(e){return $($({},e),{},{lines:e.lines.map((function(e){return e.endsWith("\r")?e.substring(0,e.length-1):e}))})}))})}function K(e){Array.isArray(e)||(e=[e]);return!e.some((function(e){return e.hunks.some((function(e){return e.lines.some((function(e){return!e.startsWith("\\")&&e.endsWith("\r")}))}))}))}function Q(e){Array.isArray(e)||(e=[e]);return e.some((function(e){return e.hunks.some((function(e){return e.lines.some((function(e){return e.endsWith("\r")}))}))}))&&e.every((function(e){return e.hunks.every((function(e){return e.lines.every((function(t,n){var r;return t.startsWith("\\")||t.endsWith("\r")||((r=e.lines[n+1])===null||r===void 0?void 0:r.startsWith("\\"))}))}))}))}function Z(e){var t=e.split(/\n/),n=[],r=0;function o(){var e={};n.push(e);while(r<t.length){var o=t[r];if(/^(\-\-\-|\+\+\+|@@)\s/.test(o))break;var a=/^(?:Index:|diff(?: -r \w+)+)\s+(.+?)\s*$/.exec(o);a&&(e.index=a[1]);r++}i(e);i(e);e.hunks=[];while(r<t.length){var c=t[r];if(/^(Index:\s|diff\s|\-\-\-\s|\+\+\+\s|===================================================================)/.test(c))break;if(/^@@/.test(c))e.hunks.push(s());else{if(c)throw new Error("Unknown line "+(r+1)+" "+JSON.stringify(c));r++}}}function i(e){var n=/^(---|\+\+\+)\s+(.*)\r?$/.exec(t[r]);if(n){var o=n[1]==="---"?"old":"new";var i=n[2].split("\t",2);var s=i[0].replace(/\\\\/g,"\\");/^".*"$/.test(s)&&(s=s.substr(1,s.length-2));e[o+"FileName"]=s;e[o+"Header"]=(i[1]||"").trim();r++}}function s(){var e=r,n=t[r++],o=n.split(/@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/);var i={oldStart:+o[1],oldLines:typeof o[2]==="undefined"?1:+o[2],newStart:+o[3],newLines:typeof o[4]==="undefined"?1:+o[4],lines:[]};i.oldLines===0&&(i.oldStart+=1);i.newLines===0&&(i.newStart+=1);var s=0,a=0;for(;r<t.length&&(a<i.oldLines||s<i.newLines||(c=t[r])!==null&&c!==void 0&&c.startsWith("\\"));r++){var c;var l=t[r].length==0&&r!=t.length-1?" ":t[r][0];if(l!=="+"&&l!=="-"&&l!==" "&&l!=="\\")throw new Error("Hunk at line ".concat(e+1," contained invalid line ").concat(t[r]));i.lines.push(t[r]);if(l==="+")s++;else if(l==="-")a++;else if(l===" "){s++;a++}}s||i.newLines!==1||(i.newLines=0);a||i.oldLines!==1||(i.oldLines=0);if(s!==i.newLines)throw new Error("Added line count did not match for hunk at line "+(e+1));if(a!==i.oldLines)throw new Error("Removed line count did not match for hunk at line "+(e+1));return i}while(r<t.length)o();return n}function X(e,t,n){var r=true,o=false,i=false,s=1;return function a(){if(r&&!i){o?s++:r=false;if(e+s<=n)return e+s;i=true}if(!o){i||(r=true);if(t<=e-s)return e-s++;o=true;return a()}}}function Y(e,t){var n=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};typeof t==="string"&&(t=Z(t));if(Array.isArray(t)){if(t.length>1)throw new Error("applyPatch only works with a single input.");t=t[0]}(n.autoConvertLineEndings||n.autoConvertLineEndings==null)&&(h(e)&&K(t)?t=J(t):d(e)&&Q(t)&&(t=G(t)));var r=e.split("\n"),o=t.hunks,i=n.compareLine||function(e,t,n,r){return t===r},s=n.fuzzFactor||0,a=0;if(s<0||!Number.isInteger(s))throw new Error("fuzzFactor must be a non-negative integer");if(!o.length)return e;var c="",l=false,u=false;for(var f=0;f<o[o.length-1].lines.length;f++){var p=o[o.length-1].lines[f];p[0]=="\\"&&(c[0]=="+"?l=true:c[0]=="-"&&(u=true));c=p}if(l){if(u){if(!s&&r[r.length-1]=="")return false}else if(r[r.length-1]=="")r.pop();else if(!s)return false}else if(u)if(r[r.length-1]!="")r.push("");else if(!s)return false;function m(e,t,n){var o=arguments.length>3&&arguments[3]!==void 0?arguments[3]:0;var s=!(arguments.length>4&&arguments[4]!==void 0)||arguments[4];var a=arguments.length>5&&arguments[5]!==void 0?arguments[5]:[];var c=arguments.length>6&&arguments[6]!==void 0?arguments[6]:0;var l=0;var u=false;for(;o<e.length;o++){var f=e[o],p=f.length>0?f[0]:" ",h=f.length>0?f.substr(1):f;if(p==="-"){if(!i(t+1,r[t],p,h)){if(!n||r[t]==null)return null;a[c]=r[t];return m(e,t+1,n-1,o,false,a,c+1)}t++;l=0}if(p==="+"){if(!s)return null;a[c]=h;c++;l=0;u=true}if(p===" "){l++;a[c]=r[t];if(!i(t+1,r[t],p,h))return u||!n?null:r[t]&&(m(e,t+1,n-1,o+1,false,a,c+1)||m(e,t+1,n-1,o,false,a,c+1))||m(e,t,n-1,o+1,false,a,c);c++;s=true;u=false;t++}}c-=l;t-=l;a.length=c;return{patchedLines:a,oldLineLastI:t-1}}var y=[];var g=0;for(var v=0;v<o.length;v++){var b=o[v];var w=void 0;var x=r.length-b.oldLines+s;var j=void 0;for(var k=0;k<=s;k++){j=b.oldStart+g-1;var A=X(j,a,x);for(;j!==void 0;j=A()){w=m(b.lines,j,k);if(w)break}if(w)break}if(!w)return false;for(var T=a;T<j;T++)y.push(r[T]);for(var O=0;O<w.patchedLines.length;O++){var C=w.patchedLines[O];y.push(C)}a=w.oldLineLastI+1;g=j+1-b.oldStart}for(var E=a;E<r.length;E++)y.push(r[E]);return y.join("\n")}function ee(e,t){typeof e==="string"&&(e=Z(e));var n=0;function r(){var o=e[n++];if(!o)return t.complete();t.loadFile(o,(function(e,n){if(e)return t.complete(e);var i=Y(n,o,t);t.patched(o,i,(function(e){if(e)return t.complete(e);r()}))}))}r()}function te(e,t,n,r,o,i,s){s||(s={});typeof s==="function"&&(s={callback:s});typeof s.context==="undefined"&&(s.context=4);if(s.newlineIsToken)throw new Error("newlineIsToken may not be used with patch-generation functions, only with diffing functions");if(!s.callback)return l(A(n,r,s));var a=s,c=a.callback;A(n,r,$($({},s),{},{callback:function(e){var t=l(e);c(t)}}));function l(n){if(n){n.push({value:"",lines:[]});var r=[];var a=0,c=0,l=[],u=1,f=1;var p=function(){var e=n[h],t=e.lines||ie(e.value);e.lines=t;if(e.added||e.removed){var o;if(!a){var i=n[h-1];a=u;c=f;if(i){l=s.context>0?v(i.lines.slice(-s.context)):[];a-=l.length;c-=l.length}}(o=l).push.apply(o,N(t.map((function(t){return(e.added?"+":"-")+t}))));e.added?f+=t.length:u+=t.length}else{if(a)if(t.length<=s.context*2&&h<n.length-2){var p;(p=l).push.apply(p,N(v(t)))}else{var d;var m=Math.min(t.length,s.context);(d=l).push.apply(d,N(v(t.slice(0,m))));var y={oldStart:a,oldLines:u-a+m,newStart:c,newLines:f-c+m,lines:l};r.push(y);a=0;c=0;l=[]}u+=t.length;f+=t.length}};for(var h=0;h<n.length;h++)p();for(var d=0,m=r;d<m.length;d++){var y=m[d];for(var g=0;g<y.lines.length;g++)if(y.lines[g].endsWith("\n"))y.lines[g]=y.lines[g].slice(0,-1);else{y.lines.splice(g+1,0,"\\ No newline at end of file");g++}}return{oldFileName:e,newFileName:t,oldHeader:o,newHeader:i,hunks:r}}function v(e){return e.map((function(e){return" "+e}))}}}function ne(e){if(Array.isArray(e))return e.map(ne).join("\n");var t=[];e.oldFileName==e.newFileName&&t.push("Index: "+e.oldFileName);t.push("===================================================================");t.push("--- "+e.oldFileName+(typeof e.oldHeader==="undefined"?"":"\t"+e.oldHeader));t.push("+++ "+e.newFileName+(typeof e.newHeader==="undefined"?"":"\t"+e.newHeader));for(var n=0;n<e.hunks.length;n++){var r=e.hunks[n];r.oldLines===0&&(r.oldStart-=1);r.newLines===0&&(r.newStart-=1);t.push("@@ -"+r.oldStart+","+r.oldLines+" +"+r.newStart+","+r.newLines+" @@");t.push.apply(t,r.lines)}return t.join("\n")+"\n"}function re(e,t,n,r,o,i,s){var a;typeof s==="function"&&(s={callback:s});if((a=s)===null||a===void 0||!a.callback){var c=te(e,t,n,r,o,i,s);if(!c)return;return ne(c)}var l=s,u=l.callback;te(e,t,n,r,o,i,$($({},s),{},{callback:function(e){e?u(ne(e)):u()}}))}function oe(e,t,n,r,o,i){return re(e,e,t,n,r,o,i)}function ie(e){var t=e.endsWith("\n");var n=e.split("\n").map((function(e){return e+"\n"}));t?n.pop():n.push(n.pop().slice(0,-1));return n}function se(e,t){return e.length===t.length&&ae(e,t)}function ae(e,t){if(t.length>e.length)return false;for(var n=0;n<t.length;n++)if(t[n]!==e[n])return false;return true}function ce(e){var t=Te(e.lines),n=t.oldLines,r=t.newLines;n!==void 0?e.oldLines=n:delete e.oldLines;r!==void 0?e.newLines=r:delete e.newLines}function le(e,t,n){e=ue(e,n);t=ue(t,n);var r={};(e.index||t.index)&&(r.index=e.index||t.index);if(e.newFileName||t.newFileName)if(fe(e))if(fe(t)){r.oldFileName=pe(r,e.oldFileName,t.oldFileName);r.newFileName=pe(r,e.newFileName,t.newFileName);r.oldHeader=pe(r,e.oldHeader,t.oldHeader);r.newHeader=pe(r,e.newHeader,t.newHeader)}else{r.oldFileName=e.oldFileName;r.newFileName=e.newFileName;r.oldHeader=e.oldHeader;r.newHeader=e.newHeader}else{r.oldFileName=t.oldFileName||e.oldFileName;r.newFileName=t.newFileName||e.newFileName;r.oldHeader=t.oldHeader||e.oldHeader;r.newHeader=t.newHeader||e.newHeader}r.hunks=[];var o=0,i=0,s=0,a=0;while(o<e.hunks.length||i<t.hunks.length){var c=e.hunks[o]||{oldStart:Infinity},l=t.hunks[i]||{oldStart:Infinity};if(he(c,l)){r.hunks.push(de(c,s));o++;a+=c.newLines-c.oldLines}else if(he(l,c)){r.hunks.push(de(l,a));i++;s+=l.newLines-l.oldLines}else{var u={oldStart:Math.min(c.oldStart,l.oldStart),oldLines:0,newStart:Math.min(c.newStart+s,l.oldStart+a),newLines:0,lines:[]};me(u,c.oldStart,c.lines,l.oldStart,l.lines);i++;o++;r.hunks.push(u)}}return r}function ue(e,t){if(typeof e==="string"){if(/^@@/m.test(e)||/^Index:/m.test(e))return Z(e)[0];if(!t)throw new Error("Must provide a base reference or pass in a patch");return te(void 0,void 0,t,e)}return e}function fe(e){return e.newFileName&&e.newFileName!==e.oldFileName}function pe(e,t,n){if(t===n)return t;e.conflict=true;return{mine:t,theirs:n}}function he(e,t){return e.oldStart<t.oldStart&&e.oldStart+e.oldLines<t.oldStart}function de(e,t){return{oldStart:e.oldStart,oldLines:e.oldLines,newStart:e.newStart+t,newLines:e.newLines,lines:e.lines}}function me(e,t,n,r,o){var i={offset:t,lines:n,index:0},s={offset:r,lines:o,index:0};be(e,i,s);be(e,s,i);while(i.index<i.lines.length&&s.index<s.lines.length){var a=i.lines[i.index],c=s.lines[s.index];if(a[0]!=="-"&&a[0]!=="+"||c[0]!=="-"&&c[0]!=="+")if(a[0]==="+"&&c[0]===" "){var l;(l=e.lines).push.apply(l,N(xe(i)))}else if(c[0]==="+"&&a[0]===" "){var u;(u=e.lines).push.apply(u,N(xe(s)))}else if(a[0]==="-"&&c[0]===" ")ge(e,i,s);else if(c[0]==="-"&&a[0]===" ")ge(e,s,i,true);else if(a===c){e.lines.push(a);i.index++;s.index++}else ve(e,xe(i),xe(s));else ye(e,i,s)}we(e,i);we(e,s);ce(e)}function ye(e,t,n){var r=xe(t),o=xe(n);if(ke(r)&&ke(o)){if(ae(r,o)&&Ae(n,r,r.length-o.length)){var i;(i=e.lines).push.apply(i,N(r));return}if(ae(o,r)&&Ae(t,o,o.length-r.length)){var s;(s=e.lines).push.apply(s,N(o));return}}else if(se(r,o)){var a;(a=e.lines).push.apply(a,N(r));return}ve(e,r,o)}function ge(e,t,n,r){var o=xe(t),i=je(n,o);if(i.merged){var s;(s=e.lines).push.apply(s,N(i.merged))}else ve(e,r?i:o,r?o:i)}function ve(e,t,n){e.conflict=true;e.lines.push({conflict:true,mine:t,theirs:n})}function be(e,t,n){while(t.offset<n.offset&&t.index<t.lines.length){var r=t.lines[t.index++];e.lines.push(r);t.offset++}}function we(e,t){while(t.index<t.lines.length){var n=t.lines[t.index++];e.lines.push(n)}}function xe(e){var t=[],n=e.lines[e.index][0];while(e.index<e.lines.length){var r=e.lines[e.index];n==="-"&&r[0]==="+"&&(n="+");if(n!==r[0])break;t.push(r);e.index++}return t}function je(e,t){var n=[],r=[],o=0,i=false,s=false;while(o<t.length&&e.index<e.lines.length){var a=e.lines[e.index],c=t[o];if(c[0]==="+")break;i=i||a[0]!==" ";r.push(c);o++;if(a[0]==="+"){s=true;while(a[0]==="+"){n.push(a);a=e.lines[++e.index]}}if(c.substr(1)===a.substr(1)){n.push(a);e.index++}else s=true}(t[o]||"")[0]==="+"&&i&&(s=true);if(s)return n;while(o<t.length)r.push(t[o++]);return{merged:r,changes:n}}function ke(e){return e.reduce((function(e,t){return e&&t[0]==="-"}),true)}function Ae(e,t,n){for(var r=0;r<n;r++){var o=t[t.length-n+r].substr(1);if(e.lines[e.index+r]!==" "+o)return false}e.index+=n;return true}function Te(e){var t=0;var n=0;e.forEach((function(e){if(typeof e!=="string"){var r=Te(e.mine);var o=Te(e.theirs);t!==void 0&&(r.oldLines===o.oldLines?t+=r.oldLines:t=void 0);n!==void 0&&(r.newLines===o.newLines?n+=r.newLines:n=void 0)}else{n===void 0||e[0]!=="+"&&e[0]!==" "||n++;t===void 0||e[0]!=="-"&&e[0]!==" "||t++}}));return{oldLines:t,newLines:n}}function Oe(e){return Array.isArray(e)?e.map(Oe).reverse():$($({},e),{},{oldFileName:e.newFileName,oldHeader:e.newHeader,newFileName:e.oldFileName,newHeader:e.oldHeader,hunks:e.hunks.map((function(e){return{oldLines:e.newLines,oldStart:e.newStart,newLines:e.oldLines,newStart:e.oldStart,lines:e.lines.map((function(e){return e.startsWith("-")?"+".concat(e.slice(1)):e.startsWith("+")?"-".concat(e.slice(1)):e}))}}))})}function Ce(e){var t,n,r=[];for(var o=0;o<e.length;o++){t=e[o];n=t.added?1:t.removed?-1:0;r.push([n,t.value])}return r}function Ee(e){var t=[];for(var n=0;n<e.length;n++){var r=e[n];r.added?t.push("<ins>"):r.removed&&t.push("<del>");t.push(Se(r.value));r.added?t.push("</ins>"):r.removed&&t.push("</del>")}return t.join("")}function Se(e){var t=e;t=t.replace(/&/g,"&amp;");t=t.replace(/</g,"&lt;");t=t.replace(/>/g,"&gt;");t=t.replace(/"/g,"&quot;");return t}e.Diff=t;e.applyPatch=Y;e.applyPatches=ee;e.canonicalize=V;e.convertChangesToDMP=Ce;e.convertChangesToXML=Ee;e.createPatch=oe;e.createTwoFilesPatch=re;e.diffArrays=U;e.diffChars=o;e.diffCss=S;e.diffJson=H;e.diffLines=A;e.diffSentences=C;e.diffTrimmedLines=T;e.diffWords=v;e.diffWordsWithSpace=x;e.formatPatch=ne;e.merge=le;e.parsePatch=Z;e.reversePatch=Oe;e.structuredPatch=te}))},{}],93:[function(e,t,n){var r="Expected a function";var o="__lodash_hash_undefined__";var i=1/0;var s="[object Function]",a="[object GeneratorFunction]",c="[object Symbol]";var l=/\.|\[(?:[^[\]]*|(["'])(?:(?!\1)[^\\]|\\.)*?\1)\]/,u=/^\w*$/,f=/^\./,p=/[^.[\]]+|\[(?:(-?\d+(?:\.\d+)?)|(["'])((?:(?!\2)[^\\]|\\.)*?)\2)\]|(?=(?:\.|\[\])(?:\.|\[\]|$))/g;var h=/[\\^$.*+?()[\]{}|]/g;var d=/\\(\\)?/g;var m=/^\[object .+?Constructor\]$/;var y=typeof global=="object"&&global&&global.Object===Object&&global;var g=typeof self=="object"&&self&&self.Object===Object&&self;var v=y||g||Function("return this")();
/**
 * Gets the value at `key` of `object`.
 *
 * @private
 * @param {Object} [object] The object to query.
 * @param {string} key The key of the property to get.
 * @returns {*} Returns the property value.
 */function b(e,t){return e==null?void 0:e[t]}
/**
 * Checks if `value` is a host object in IE < 9.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a host object, else `false`.
 */function w(e){var t=false;if(e!=null&&typeof e.toString!="function")try{t=!!(e+"")}catch(e){}return t}var x=Array.prototype,j=Function.prototype,k=Object.prototype;var A=v["__core-js_shared__"];var T=function(){var e=/[^.]+$/.exec(A&&A.keys&&A.keys.IE_PROTO||"");return e?"Symbol(src)_1."+e:""}();var O=j.toString;var C=k.hasOwnProperty;var E=k.toString;var S=RegExp("^"+O.call(C).replace(h,"\\$&").replace(/hasOwnProperty|(function).*?(?=\\\()| for .+?(?=\\\])/g,"$1.*?")+"$");var P=v.Symbol,$=x.splice;var I=se(v,"Map"),M=se(Object,"create");var F=P?P.prototype:void 0,L=F?F.toString:void 0;
/**
 * Creates a hash object.
 *
 * @private
 * @constructor
 * @param {Array} [entries] The key-value pairs to cache.
 */function N(e){var t=-1,n=e?e.length:0;this.clear();while(++t<n){var r=e[t];this.set(r[0],r[1])}}function D(){this.__data__=M?M(null):{}}
/**
 * Removes `key` and its value from the hash.
 *
 * @private
 * @name delete
 * @memberOf Hash
 * @param {Object} hash The hash to modify.
 * @param {string} key The key of the value to remove.
 * @returns {boolean} Returns `true` if the entry was removed, else `false`.
 */function W(e){return this.has(e)&&delete this.__data__[e]}
/**
 * Gets the hash value for `key`.
 *
 * @private
 * @name get
 * @memberOf Hash
 * @param {string} key The key of the value to get.
 * @returns {*} Returns the entry value.
 */function _(e){var t=this.__data__;if(M){var n=t[e];return n===o?void 0:n}return C.call(t,e)?t[e]:void 0}
/**
 * Checks if a hash value for `key` exists.
 *
 * @private
 * @name has
 * @memberOf Hash
 * @param {string} key The key of the entry to check.
 * @returns {boolean} Returns `true` if an entry for `key` exists, else `false`.
 */function B(e){var t=this.__data__;return M?t[e]!==void 0:C.call(t,e)}
/**
 * Sets the hash `key` to `value`.
 *
 * @private
 * @name set
 * @memberOf Hash
 * @param {string} key The key of the value to set.
 * @param {*} value The value to set.
 * @returns {Object} Returns the hash instance.
 */function z(e,t){var n=this.__data__;n[e]=M&&t===void 0?o:t;return this}N.prototype.clear=D;N.prototype.delete=W;N.prototype.get=_;N.prototype.has=B;N.prototype.set=z;
/**
 * Creates an list cache object.
 *
 * @private
 * @constructor
 * @param {Array} [entries] The key-value pairs to cache.
 */function q(e){var t=-1,n=e?e.length:0;this.clear();while(++t<n){var r=e[t];this.set(r[0],r[1])}}function H(){this.__data__=[]}
/**
 * Removes `key` and its value from the list cache.
 *
 * @private
 * @name delete
 * @memberOf ListCache
 * @param {string} key The key of the value to remove.
 * @returns {boolean} Returns `true` if the entry was removed, else `false`.
 */function V(e){var t=this.__data__,n=ee(t,e);if(n<0)return false;var r=t.length-1;n==r?t.pop():$.call(t,n,1);return true}
/**
 * Gets the list cache value for `key`.
 *
 * @private
 * @name get
 * @memberOf ListCache
 * @param {string} key The key of the value to get.
 * @returns {*} Returns the entry value.
 */function R(e){var t=this.__data__,n=ee(t,e);return n<0?void 0:t[n][1]}
/**
 * Checks if a list cache value for `key` exists.
 *
 * @private
 * @name has
 * @memberOf ListCache
 * @param {string} key The key of the entry to check.
 * @returns {boolean} Returns `true` if an entry for `key` exists, else `false`.
 */function U(e){return ee(this.__data__,e)>-1}
/**
 * Sets the list cache `key` to `value`.
 *
 * @private
 * @name set
 * @memberOf ListCache
 * @param {string} key The key of the value to set.
 * @param {*} value The value to set.
 * @returns {Object} Returns the list cache instance.
 */function J(e,t){var n=this.__data__,r=ee(n,e);r<0?n.push([e,t]):n[r][1]=t;return this}q.prototype.clear=H;q.prototype.delete=V;q.prototype.get=R;q.prototype.has=U;q.prototype.set=J;
/**
 * Creates a map cache object to store key-value pairs.
 *
 * @private
 * @constructor
 * @param {Array} [entries] The key-value pairs to cache.
 */function G(e){var t=-1,n=e?e.length:0;this.clear();while(++t<n){var r=e[t];this.set(r[0],r[1])}}function K(){this.__data__={hash:new N,map:new(I||q),string:new N}}
/**
 * Removes `key` and its value from the map.
 *
 * @private
 * @name delete
 * @memberOf MapCache
 * @param {string} key The key of the value to remove.
 * @returns {boolean} Returns `true` if the entry was removed, else `false`.
 */function Q(e){return ie(this,e).delete(e)}
/**
 * Gets the map value for `key`.
 *
 * @private
 * @name get
 * @memberOf MapCache
 * @param {string} key The key of the value to get.
 * @returns {*} Returns the entry value.
 */function Z(e){return ie(this,e).get(e)}
/**
 * Checks if a map value for `key` exists.
 *
 * @private
 * @name has
 * @memberOf MapCache
 * @param {string} key The key of the entry to check.
 * @returns {boolean} Returns `true` if an entry for `key` exists, else `false`.
 */function X(e){return ie(this,e).has(e)}
/**
 * Sets the map `key` to `value`.
 *
 * @private
 * @name set
 * @memberOf MapCache
 * @param {string} key The key of the value to set.
 * @param {*} value The value to set.
 * @returns {Object} Returns the map cache instance.
 */function Y(e,t){ie(this,e).set(e,t);return this}G.prototype.clear=K;G.prototype.delete=Q;G.prototype.get=Z;G.prototype.has=X;G.prototype.set=Y;
/**
 * Gets the index at which the `key` is found in `array` of key-value pairs.
 *
 * @private
 * @param {Array} array The array to inspect.
 * @param {*} key The key to search for.
 * @returns {number} Returns the index of the matched value, else `-1`.
 */function ee(e,t){var n=e.length;while(n--)if(de(e[n][0],t))return n;return-1}
/**
 * The base implementation of `_.get` without support for default values.
 *
 * @private
 * @param {Object} object The object to query.
 * @param {Array|string} path The path of the property to get.
 * @returns {*} Returns the resolved value.
 */function te(e,t){t=ae(t,e)?[t]:oe(t);var n=0,r=t.length;while(e!=null&&n<r)e=e[fe(t[n++])];return n&&n==r?e:void 0}
/**
 * The base implementation of `_.isNative` without bad shim checks.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a native function,
 *  else `false`.
 */function ne(e){if(!ge(e)||le(e))return false;var t=ye(e)||w(e)?S:m;return t.test(pe(e))}
/**
 * The base implementation of `_.toString` which doesn't convert nullish
 * values to empty strings.
 *
 * @private
 * @param {*} value The value to process.
 * @returns {string} Returns the string.
 */function re(e){if(typeof e=="string")return e;if(be(e))return L?L.call(e):"";var t=e+"";return t=="0"&&1/e==-i?"-0":t}
/**
 * Casts `value` to a path array if it's not one.
 *
 * @private
 * @param {*} value The value to inspect.
 * @returns {Array} Returns the cast property path array.
 */function oe(e){return me(e)?e:ue(e)}
/**
 * Gets the data for `map`.
 *
 * @private
 * @param {Object} map The map to query.
 * @param {string} key The reference key.
 * @returns {*} Returns the map data.
 */function ie(e,t){var n=e.__data__;return ce(t)?n[typeof t=="string"?"string":"hash"]:n.map}
/**
 * Gets the native function at `key` of `object`.
 *
 * @private
 * @param {Object} object The object to query.
 * @param {string} key The key of the method to get.
 * @returns {*} Returns the function if it's native, else `undefined`.
 */function se(e,t){var n=b(e,t);return ne(n)?n:void 0}
/**
 * Checks if `value` is a property name and not a property path.
 *
 * @private
 * @param {*} value The value to check.
 * @param {Object} [object] The object to query keys on.
 * @returns {boolean} Returns `true` if `value` is a property name, else `false`.
 */function ae(e,t){if(me(e))return false;var n=typeof e;return!(n!="number"&&n!="symbol"&&n!="boolean"&&e!=null&&!be(e))||(u.test(e)||!l.test(e)||t!=null&&e in Object(t))}
/**
 * Checks if `value` is suitable for use as unique object key.
 *
 * @private
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is suitable, else `false`.
 */function ce(e){var t=typeof e;return t=="string"||t=="number"||t=="symbol"||t=="boolean"?e!=="__proto__":e===null}
/**
 * Checks if `func` has its source masked.
 *
 * @private
 * @param {Function} func The function to check.
 * @returns {boolean} Returns `true` if `func` is masked, else `false`.
 */function le(e){return!!T&&T in e}
/**
 * Converts `string` to a property path array.
 *
 * @private
 * @param {string} string The string to convert.
 * @returns {Array} Returns the property path array.
 */var ue=he((function(e){e=we(e);var t=[];f.test(e)&&t.push("");e.replace(p,(function(e,n,r,o){t.push(r?o.replace(d,"$1"):n||e)}));return t}));
/**
 * Converts `value` to a string key if it's not a string or symbol.
 *
 * @private
 * @param {*} value The value to inspect.
 * @returns {string|symbol} Returns the key.
 */function fe(e){if(typeof e=="string"||be(e))return e;var t=e+"";return t=="0"&&1/e==-i?"-0":t}
/**
 * Converts `func` to its source code.
 *
 * @private
 * @param {Function} func The function to process.
 * @returns {string} Returns the source code.
 */function pe(e){if(e!=null){try{return O.call(e)}catch(e){}try{return e+""}catch(e){}}return""}
/**
 * Creates a function that memoizes the result of `func`. If `resolver` is
 * provided, it determines the cache key for storing the result based on the
 * arguments provided to the memoized function. By default, the first argument
 * provided to the memoized function is used as the map cache key. The `func`
 * is invoked with the `this` binding of the memoized function.
 *
 * **Note:** The cache is exposed as the `cache` property on the memoized
 * function. Its creation may be customized by replacing the `_.memoize.Cache`
 * constructor with one whose instances implement the
 * [`Map`](http://ecma-international.org/ecma-262/7.0/#sec-properties-of-the-map-prototype-object)
 * method interface of `delete`, `get`, `has`, and `set`.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Function
 * @param {Function} func The function to have its output memoized.
 * @param {Function} [resolver] The function to resolve the cache key.
 * @returns {Function} Returns the new memoized function.
 * @example
 *
 * var object = { 'a': 1, 'b': 2 };
 * var other = { 'c': 3, 'd': 4 };
 *
 * var values = _.memoize(_.values);
 * values(object);
 * // => [1, 2]
 *
 * values(other);
 * // => [3, 4]
 *
 * object.a = 2;
 * values(object);
 * // => [1, 2]
 *
 * // Modify the result cache.
 * values.cache.set(object, ['a', 'b']);
 * values(object);
 * // => ['a', 'b']
 *
 * // Replace `_.memoize.Cache`.
 * _.memoize.Cache = WeakMap;
 */function he(e,t){if(typeof e!="function"||t&&typeof t!="function")throw new TypeError(r);var n=function(){var r=arguments,o=t?t.apply(this,r):r[0],i=n.cache;if(i.has(o))return i.get(o);var s=e.apply(this,r);n.cache=i.set(o,s);return s};n.cache=new(he.Cache||G);return n}he.Cache=G;
/**
 * Performs a
 * [`SameValueZero`](http://ecma-international.org/ecma-262/7.0/#sec-samevaluezero)
 * comparison between two values to determine if they are equivalent.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to compare.
 * @param {*} other The other value to compare.
 * @returns {boolean} Returns `true` if the values are equivalent, else `false`.
 * @example
 *
 * var object = { 'a': 1 };
 * var other = { 'a': 1 };
 *
 * _.eq(object, object);
 * // => true
 *
 * _.eq(object, other);
 * // => false
 *
 * _.eq('a', 'a');
 * // => true
 *
 * _.eq('a', Object('a'));
 * // => false
 *
 * _.eq(NaN, NaN);
 * // => true
 */function de(e,t){return e===t||e!==e&&t!==t}
/**
 * Checks if `value` is classified as an `Array` object.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an array, else `false`.
 * @example
 *
 * _.isArray([1, 2, 3]);
 * // => true
 *
 * _.isArray(document.body.children);
 * // => false
 *
 * _.isArray('abc');
 * // => false
 *
 * _.isArray(_.noop);
 * // => false
 */var me=Array.isArray;
/**
 * Checks if `value` is classified as a `Function` object.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a function, else `false`.
 * @example
 *
 * _.isFunction(_);
 * // => true
 *
 * _.isFunction(/abc/);
 * // => false
 */function ye(e){var t=ge(e)?E.call(e):"";return t==s||t==a}
/**
 * Checks if `value` is the
 * [language type](http://www.ecma-international.org/ecma-262/7.0/#sec-ecmascript-language-types)
 * of `Object`. (e.g. arrays, functions, objects, regexes, `new Number(0)`, and `new String('')`)
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an object, else `false`.
 * @example
 *
 * _.isObject({});
 * // => true
 *
 * _.isObject([1, 2, 3]);
 * // => true
 *
 * _.isObject(_.noop);
 * // => true
 *
 * _.isObject(null);
 * // => false
 */function ge(e){var t=typeof e;return!!e&&(t=="object"||t=="function")}
/**
 * Checks if `value` is object-like. A value is object-like if it's not `null`
 * and has a `typeof` result of "object".
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is object-like, else `false`.
 * @example
 *
 * _.isObjectLike({});
 * // => true
 *
 * _.isObjectLike([1, 2, 3]);
 * // => true
 *
 * _.isObjectLike(_.noop);
 * // => false
 *
 * _.isObjectLike(null);
 * // => false
 */function ve(e){return!!e&&typeof e=="object"}
/**
 * Checks if `value` is classified as a `Symbol` primitive or object.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a symbol, else `false`.
 * @example
 *
 * _.isSymbol(Symbol.iterator);
 * // => true
 *
 * _.isSymbol('abc');
 * // => false
 */function be(e){return typeof e=="symbol"||ve(e)&&E.call(e)==c}
/**
 * Converts `value` to a string. An empty string is returned for `null`
 * and `undefined` values. The sign of `-0` is preserved.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to process.
 * @returns {string} Returns the string.
 * @example
 *
 * _.toString(null);
 * // => ''
 *
 * _.toString(-0);
 * // => '-0'
 *
 * _.toString([1, 2, 3]);
 * // => '1,2,3'
 */function we(e){return e==null?"":re(e)}
/**
 * Gets the value at `path` of `object`. If the resolved value is
 * `undefined`, the `defaultValue` is returned in its place.
 *
 * @static
 * @memberOf _
 * @since 3.7.0
 * @category Object
 * @param {Object} object The object to query.
 * @param {Array|string} path The path of the property to get.
 * @param {*} [defaultValue] The value returned for `undefined` resolved values.
 * @returns {*} Returns the resolved value.
 * @example
 *
 * var object = { 'a': [{ 'b': { 'c': 3 } }] };
 *
 * _.get(object, 'a[0].b.c');
 * // => 3
 *
 * _.get(object, ['a', '0', 'b', 'c']);
 * // => 3
 *
 * _.get(object, 'a.b.c', 'default');
 * // => 'default'
 */function xe(e,t,n){var r=e==null?void 0:te(e,t);return r===void 0?n:r}t.exports=xe},{}],94:[function(e,t,n){t.exports={stdout:false,stderr:false}},{}],95:[function(e,t,n){(function(e,r){typeof n==="object"&&typeof t!=="undefined"?t.exports=r():typeof define==="function"&&define.amd?define(r):e.typeDetect=r()})(this,(function(){var e=typeof Promise==="function";var t=typeof self==="object"?self:global;var n=typeof Symbol!=="undefined";var r=typeof Map!=="undefined";var o=typeof Set!=="undefined";var i=typeof WeakMap!=="undefined";var s=typeof WeakSet!=="undefined";var a=typeof DataView!=="undefined";var c=n&&typeof Symbol.iterator!=="undefined";var l=n&&typeof Symbol.toStringTag!=="undefined";var u=o&&typeof Set.prototype.entries==="function";var f=r&&typeof Map.prototype.entries==="function";var p=u&&Object.getPrototypeOf((new Set).entries());var h=f&&Object.getPrototypeOf((new Map).entries());var d=c&&typeof Array.prototype[Symbol.iterator]==="function";var m=d&&Object.getPrototypeOf([][Symbol.iterator]());var y=c&&typeof String.prototype[Symbol.iterator]==="function";var g=y&&Object.getPrototypeOf(""[Symbol.iterator]());var v=8;var b=-1;
/**
 * ### typeOf (obj)
 *
 * Uses `Object.prototype.toString` to determine the type of an object,
 * normalising behaviour across engine versions & well optimised.
 *
 * @param {Mixed} object
 * @return {String} object type
 * @api public
 */function w(n){var c=typeof n;if(c!=="object")return c;if(n===null)return"null";if(n===t)return"global";if(Array.isArray(n)&&(l===false||!(Symbol.toStringTag in n)))return"Array";if(typeof window==="object"&&window!==null){if(typeof window.location==="object"&&n===window.location)return"Location";if(typeof window.document==="object"&&n===window.document)return"Document";if(typeof window.navigator==="object"){if(typeof window.navigator.mimeTypes==="object"&&n===window.navigator.mimeTypes)return"MimeTypeArray";if(typeof window.navigator.plugins==="object"&&n===window.navigator.plugins)return"PluginArray"}if((typeof window.HTMLElement==="function"||typeof window.HTMLElement==="object")&&n instanceof window.HTMLElement){if(n.tagName==="BLOCKQUOTE")return"HTMLQuoteElement";if(n.tagName==="TD")return"HTMLTableDataCellElement";if(n.tagName==="TH")return"HTMLTableHeaderCellElement"}}var u=l&&n[Symbol.toStringTag];if(typeof u==="string")return u;var f=Object.getPrototypeOf(n);return f===RegExp.prototype?"RegExp":f===Date.prototype?"Date":e&&f===Promise.prototype?"Promise":o&&f===Set.prototype?"Set":r&&f===Map.prototype?"Map":s&&f===WeakSet.prototype?"WeakSet":i&&f===WeakMap.prototype?"WeakMap":a&&f===DataView.prototype?"DataView":r&&f===h?"Map Iterator":o&&f===p?"Set Iterator":d&&f===m?"Array Iterator":y&&f===g?"String Iterator":f===null?"Object":Object.prototype.toString.call(n).slice(v,b)}return w}))},{}]},{},[2]);var t=e;const n=e.leakThreshold;const r=e.assert;const o=e.getFakes;const i=e.createStubInstance;const s=e.inject;const a=e.mock;const c=e.reset;const l=e.resetBehavior;const u=e.resetHistory;const f=e.restore;const p=e.restoreContext;const h=e.replace;const d=e.define;const m=e.replaceGetter;const y=e.replaceSetter;const g=e.spy;const v=e.stub;const b=e.fake;const w=e.useFakeTimers;const x=e.verify;const j=e.verifyAndRestore;const k=e.createSandbox;const A=e.match;const T=e.restoreObject;const O=e.expectation;const C=e.timers;const E=e.addBehavior;const S=e.promise;export{E as addBehavior,r as assert,k as createSandbox,i as createStubInstance,t as default,d as define,O as expectation,b as fake,o as getFakes,s as inject,n as leakThreshold,A as match,a as mock,S as promise,h as replace,m as replaceGetter,y as replaceSetter,c as reset,l as resetBehavior,u as resetHistory,f as restore,p as restoreContext,T as restoreObject,g as spy,v as stub,C as timers,w as useFakeTimers,x as verify,j as verifyAndRestore};

