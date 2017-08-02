---
---
'use strict';

(function($, angular){

    {% include_relative owl.carousel.2.0.0-beta.3/owl.carousel.min.js %}


    var freeradius = angular.module('freeradius',[]);

    // Add safe apply for all directives
    // freeradius.run(['$rootScope', function($rootScope) {
    //     $rootScope.online = false;
    //     $rootScope.loading = false;
    //     $rootScope.safeApply = function(fn) {
    //         var phase = this.$root.$$phase;
    //         if (phase == '$apply' || phase == '$digest') {
    //             if (fn && (typeof(fn) === 'function')) {
    //                 fn();
    //             }
    //         } else {
    //             this.$apply(fn);
    //         }
    //     };
    // }]);
    freeradius.config (function($locationProvider) {
        $locationProvider.html5Mode({
        enabled : true,
        requireBase: false,
        rewriteLinks : false
        });
    });

    // freeradius.run( function($rootScope, $location, $window) {
    //     var win = angular.element($window);

    //     $rootScope.$watch($location, function() {
    //         console.log($location.url());
    //         // return $location.path();
    //         if ($location.url().indexOf('#') != -1) {
    //             console.log(win.scrollTop());
    //         }
    //     });
    // });

    freeradius.factory('getStable', ['$http', function($http){
        return $http({
            method: 'GET',
            url: 'http://{{ site.url }}/api/info/branch/',
            // url: '/modules.json',
            params: {
                by_keyword: 'stable',
                keyword_expansion_depth: 1,
                expansion_depth: 1,
                keyword_field: 'status'
            }
        });
    }]);

    freeradius.factory('getQueryParams', ['$http', function($http){
        return function (qs) {
            qs = qs.split('+').join(' ');

            var params = {},
                tokens,
                re = /[?&]?([^=]+)=([^&]*)/g;

            while (tokens = re.exec(qs)) {
                params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
            }

            return params;
        }
    }]);

    freeradius.directive('tabTrigger', [function() {
        return {
            // scope: "",
            link: function($scope, $element, $attrs){
                $scope.toggle = function(id, closeAndOpen) {
                    // console.log('id ' , id);
                    var target_el = angular.element(id);
                    // console.log('target_el ' , target_el);

                    if (closeAndOpen) {
                        target_el.scope().active == id ? target_el.scope().active = '' : target_el.scope().active = id;
                        // console.log('target_el.scope().active ' , target_el.scope().active);
                        $scope.trigger_active == id ? $scope.trigger_active = '' : $scope.trigger_active = id;
                    } else {
                        target_el.scope().active = id;
                        $scope.trigger_active = id;
                    }
                }
            }
        };
    }]);

    freeradius.directive('tabContent', [function() {
        return {
            // scope: true,
            link: function($scope, $element, $attrs){
                if ($attrs.transition == 'slide') {
                    $($element[0]).css({display: 'none'});
                    $scope.$watch('active', function(newValue, oldValue) {
                        if (newValue == '#'+$attrs.id) {
                            $($element[0]).slideDown();
                        } else {
                            $($element[0]).slideUp();
                        }
                    });
                }
            }
        };
    }]);

    freeradius.directive('contentGroup', [function() {
        return {
            scope: true,
            link: function($scope, $element, $attrs){
                $scope.toggle = function(id, closeAndOpen) {
                    // var target_el = angular.element($(id)[0]);

                    if (closeAndOpen) {
                        $scope.active == id ? $scope.active = '' : $scope.active = id;
                    } else {
                        $scope.active = id;
                    }
                }
                $scope.$on('triggerToggle', function(e, data) {
                    $scope.toggle(data.id, data.closeAndOpen);
                });

            }
        };
    }]);

    freeradius.directive('globalHeader', [ '$window',
        function($window) {
            return {
                controller:  [
                    '$scope', '$element', '$attrs',
                    function($scope, $elem, $attrs) {
                        var win = angular.element($window);
                        var scrollOffset = $attrs.scrolloffset;
                        $scope.fixNav = false;
                        win.bind('scroll', function() {
                            var windowScroll = $window.scrollY;
                            $scope.windowScroll = windowScroll;
                            if (windowScroll > $('.global-nav').height()) {
                                $scope.fixNav = true;
                            } else {
                                $scope.fixNav = false;
                            }
                            $scope.$apply();
                        });
                    }
                ]
            };
        }
    ]);

    freeradius.controller('ModulesPage', ['$scope', '$http', '$window', '$anchorScroll', '$document', '$timeout', '$location', function($scope, $http, $window, $anchorScroll, $document, $timeout, $location) {
        $scope.activeFilter = 'all';
        $anchorScroll.yOffset = 120;
        $scope.filter = function(moduleType) {
            $scope.activeFilter = moduleType;
        };
        var win = angular.element($window);
        // var query = getQueryParams(win.prop('location').search);

        $scope.getModules = function(category, module) {
            $scope.state = 'loading';
            $http({
                method: 'GET',
                url: 'http://{{ site.url }}/api/info/component/',
                // url: '/modules.json',
                params: {
                    by_category: category,
                    expansion_depth: 1,
                    order_by: 'category'
                }
            }).then(function successCallback(response) {
                // console.log('response ' , response.data);
                $scope.modules = response.data;
                $scope.state = 'success';
                $scope.searchString = '';
                if (module) {
                    $scope.filter(category);
                    $scope.$broadcast ('triggerToggle', {'id': '#module-details-' + module, 'openAndClose': true});
                    $timeout(function() {
                        $scope.$broadcast ('triggerFixMargin');
                        $scope.goToModule(module);
                    },100);
                } else {
                    $timeout(function() {
                        $scope.$broadcast ('triggerFixMargin');
                    },100);
                }

            }, function errorCallback(response) {
                console.log('error response ' , response);
                $scope.state = 'error';
            });
        };

        $scope.changeLocation = function(category, module) {
            $location.search('s', null);
            $scope.searchString = '';
            if (category) {
                $location.search('cat', category);
            } else if (category === false) {
                $location.search('cat', null);
            }
            if (module) {
                $location.search('mod', module);
            } else {
                $location.search('mod', null);
            }
        };

        $scope.changeLocationModule = function(module) {
            if (module) {
                $location.search('mod', module);
            } else {
                $location.search('mod', null);
            }
        };

        $scope.changeLocationSearch = function(str) {
            if (str) {
                $location.search({s: str});
            } else {
                $location.search('s', null);
            }
        };

        $scope.$watch(function(){ return $location.search() }, function(newValue, oldValue){
            if (newValue.mod && newValue.mod !== oldValue.mod && newValue.cat === oldValue.cat) {
                $scope.checkLocation(false, newValue.mod);
            } else {
                $scope.checkLocation();
            }
        }, true);

        $scope.checkLocation = function(callMods, module) {
            if (!callMods && module) {
                $scope.$broadcast ('triggerToggle', {'id': '#module-details-' + module, 'openAndClose': true});
                $timeout(function() {
                    $scope.$broadcast ('triggerFixMargin');
                    $scope.goToModule(module);
                },100);
            } else {
                if ($location.search().cat) {
                    $location.search('s', null);
                    $scope.searchString = '';
                    $scope.search = '';
                    $scope.filter($location.search().cat);
                    $scope.getModules($location.search().cat, $location.search().mod);
                }
                else if ($location.search().s) {
                    $location.search('cat', null);
                    $scope.searchString = $location.search().s;
                    $scope.searchModules($location.search().s, $location.search().mod);
                }
                else if ($location.search().mod) {
                    $scope.getModules(undefined, $location.search().mod);
                }
                else {
                    $scope.getModules();
                }
            }
        }

        $scope.getModule = function(module) {
            $scope.state = 'loading';
            $http({
                method: 'GET',
                url: 'http://{{ site.url }}/api/info/component/'+module+'/',
                params: {
                    expansion_depth: 1,
                }
            }).then(function successCallback(response) {
                // console.log('response ' , response.data);
                $scope.modules = [response.data];
                $scope.state = 'success';
                $scope.$broadcast ('triggerToggle', {'id': '#module-details-' + module, 'openAndClose': true});
                $timeout(function() {
                    $scope.$broadcast ('triggerFixMargin');
                    $scope.goToModule(module);
                },100);


            }, function errorCallback(response) {
                console.log('error response ' , response);
                $scope.state = 'error';
            });
        };


        $scope.goToModule = function(module) {
            $anchorScroll('module-'+module);
        }
        $scope.searchModules = function(string, module) {
            $scope.state = 'loading';
            $scope.searchString = string;
            $http({
                method: 'GET',
                url: 'http://{{ site.url }}/api/info/component/',
                // url: '/modules.json',
                params: {
                    by_keyword: 'regex:'+string,
                    keyword_expansion_depth: 1,
                    expansion_depth: 1,
                    order_by: 'category',
                }
            }).then(function successCallback(response) {
                // console.log('response ' , response.data);
                $scope.modules = response.data;
                $scope.activeFilter = '';
                $scope.state = 'success';

                if (module) {
                    $scope.$broadcast ('triggerToggle', {'id': '#module-details-' + module, 'openAndClose': true});
                    $timeout(function() {
                        $scope.$broadcast ('triggerFixMargin');
                        $scope.goToModule(module);
                    },100);
                } else {
                    $timeout(function() {
                        $scope.$broadcast ('triggerFixMargin');
                    },100);
                }
            }, function errorCallback(response) {
                console.log('error response ' , response);
                $scope.state = 'error';
            });
        };
        $scope.checkLocation();



    }]);

    freeradius.controller('ReleaseNotesPage', ['$scope', '$http', '$window', '$location', function($scope, $http, $window, $location) {
        $scope.activeFilter = 'all';
        $scope.filter = function(moduleType) {
            $scope.activeFilter = moduleType;
        };

        var win = angular.element($window);

        $scope.getReleases = function() {
            $scope.state = 'loading';
            $http({
                method: 'GET',
                url: 'http://{{ site.url }}/api/info/branch/*/release/',
                params: {
                    expansion_depth: 2,
                    order_by: "date:desc",
                    paginate_start: 0,
                    paginate_end: 5,
                }
            }).then(function successCallback(response) {
                // console.log('response ' , response.data);
                // remove development versions from the main display
                $scope.releases = response.data.filter(function(rel) {
                    return (rel.name && rel.name.includes("x")) ? false : true;
                });
                $scope.state = 'success';

            }, function errorCallback(response) {
                console.log('error response ' , response);
                $scope.state = 'error';
            });
        };

        $scope.getAffectedModules = function(release) {
            var modules;

            var features = [];
            angular.forEach(release.features, function(value, key) {
                this.push(value);
            }, features);

            var featureComponents = [];
            angular.forEach(features, function(value, key) {
                if (value.component && value.component.length > 0) {
                    for (var i = value.component.length - 1; i >= 0; i--) {
                        // value.component[i]
                        if (value.component[i] && value.component[i].length > 0) {
                            // already in array
                        } else {
                            this.push(value.component[i]);
                        }
                    }
                }
            }, featureComponents);

            var defects = [];
            angular.forEach(release.defects, function(value, key) {
                this.push(value);
            }, defects);

            var defectComponents = [];
            if (defects && defects.length > 0) {
                angular.forEach(defects, function(value, key) {
                    if (value.component && value.component.length > 0) {
                        for (var i = value.component.length - 1; i >= 0; i--) {
                            // value.component[i]
                            this.push(value.component[i]);
                        }
                    }
                }, defectComponents);
            }

            modules = featureComponents.concat(defectComponents);
            for(var i=0; i<modules.length; ++i) {
                for(var j=i+1; j<modules.length; ++j) {
                    if(modules[i].name === modules[j].name)
                        modules.splice(j--, 1);
                }
            }

            modules.sort(function(a,b) {return (a.category > b.category) ? 1 : ((b.category > a.category) ? -1 : 0);} );

            return modules;
        }

        $scope.compareArrays = function(arr1, arr2) {
            // var ret = [];
            for(var i in arr2) {
                if(arr1.indexOf( arr2[i] ) > -1){
                    return true;
                }
            }
            return false;
        };

        $scope.getComponents = function(obj) {
            var objComponents = [];
            angular.forEach(obj.component, function(value, key) {
                    this.push(value.name);
            }, objComponents);

            // console.log('objComponents ' , objComponents);
            return objComponents;
        };

        $scope.affectedClasses = false;
        $scope.showAffected = function($event, q) {
            if (q && q != undefined) {
                $scope.affectedClasses = [q];
            } else if ($event.currentTarget.className) {
                $scope.affectedClasses = $event.currentTarget.className.split(' ');
            }
        }
        $scope.hideAffected = function() {
            $scope.affectedClasses = false;
        }

        $scope.getAffectedModulesByCategory = function(release) {
            var modules = $scope.getAffectedModules(release);
            // console.log('modules ' , modules);

            var moduleCats = moduleCats || {};
            angular.forEach(modules, function(value, key) {
                this[value.category] = this[value.category] || [];
                this[value.category].push(value);

            }, moduleCats);
            // console.log('moduleCats ' , moduleCats);

            return moduleCats;
        };

        $scope.isCritical = function(release) {
            var defects = release.defects;
            if (defects && defects != 'undefined') {
                var filtered;
                if (defects.length > 0) {
                    filtered = defects.filter(function(obj) {
                        if (obj.exploit && obj.exploit != 'undefined') {
                            // console.log('obj ' , obj.exploit);
                            return obj;
                        } else {
                            return false;
                        }
                    });
                }
                // console.log('filtered.exploit ' , filtered);
                return filtered.length > 0;
            } else {
                return false;
            }

            // return filtered && filtered[0].exploit == true;
        };

        $scope.getReleasesByDate = function(date) {
            $scope.state = 'loading';
            $http({
                method: 'GET',
                url: 'http://{{ site.url }}/api/info/branch/*/release/',
                // url: '/modules.json',
                params: {
                    expansion_depth: 2,
                    keyword_expansion_depth: 1,
                    by_keyword: 'regex:'+date,
                    keyword_field: 'date',
                    order_by: "date:desc"
                }
            }).then(function successCallback(response) {
                // console.log('response ' , response.data);
                $scope.releases = response.data;
                $scope.activeFilter = '';
                $scope.state = 'success';

            }, function errorCallback(response) {
                console.log('error response ' , response);
                $scope.state = 'error';
            });
        };

        $scope.searchReleases = function(string){
            $scope.state = 'loading';
            $scope.searchString = string;
            $http({
                method: 'GET',
                url: 'http://{{ site.url }}/api/info/branch/*/release/',
                params: {
                    by_keyword: 'regex:'+string,
                    keyword_expansion_depth: 2,
                    expansion_depth: 2,
                    order_by: "date:desc",
                }
            }).then(function successCallback(response) {
                // console.log('response ' , response.data);
                $scope.releases = response.data;
                $scope.activeFilter = '';
                $scope.state = 'success';

            }, function errorCallback(response) {
                console.log('error response ' , response);
                $scope.state = 'error';
            });

        };

        $scope.getRelease = function(branch, release) {
            $scope.state = 'loading';
            $http({
                method: 'GET',
                url: 'http://{{ site.url }}/api/info/branch/'+branch+'/release/'+release+'/',
                params: {
                    expansion_depth: 1,
                }
            }).then(function successCallback(response) {
                $scope.releases = [ response.data ];
                $scope.activeFilter = '';
                $scope.state = 'success';

            }, function errorCallback(response) {
                console.log('error response ' , response);
                $scope.state = 'error';
            });
        };


        $scope.changeLocation = function(branch, release) {
            if (branch && release) {
                $location.search('br', branch);
                $location.search('re', release);
            } else {
                $location.search({});
            }
        };

        $scope.changeLocationSearch = function(str) {
            if (str) {
                $location.search({s: str});
            } else {
                $location.search('s', null);
            }
        };

        $scope.$on('$locationChangeSuccess', function(event){
            $scope.checkLocation();
        });

        $scope.checkLocation = function() {
            if ($location.search().br && $location.search().re) {
                $scope.getRelease($location.search().br, $location.search().re);
            }
            // else if ($location.search().cat) {
            //     $scope.getModules($location.search().cat);
            // }
            else if ($location.search().s) {
                $scope.searchReleases($location.search().s);
            }
            else {
                $scope.getReleases();
            }
        };

        $scope.checkLocation();

    }]);

    freeradius.controller('GetBranches', ['$scope', '$timeout', '$http', 'getStable', function($scope, $timeout, $http, getStable) {
        // $scope.activeFilter = 'all';
        // $scope.filter = function(moduleType) {
        //     $scope.activeFilter = moduleType;
        // };
        $scope.getBranches = function(category) {
            $scope.state = 'loading';
            $http({
                method: 'GET',
                url: 'http://{{ site.url }}/api/info/branch/',
                // url: '/modules.json',
                params: {
                    expansion_depth: 3,
                    order_by: 'priority'
                }
            }).then(function successCallback(response) {
                // console.log('response ' , response.data);
                $scope.branches = response.data;
                $scope.state = 'success';

                $timeout(function(){

                    $('.owl-carousel').owlCarousel({
                        items: 1,
                        nav: true,
                        navText: ['<img class="icon_small" src="/img/arrow-circle-left.svg" alt="" />', '<img class="icon_small" src="/img/arrow-circle-right.svg" alt="" />']
                    });
                }, 1);


            }, function errorCallback(response) {
                console.log('error response ' , response);
                $scope.state = 'error';
            });
        };
        $scope.getBranches();

        $scope.getStableBranch = function() {
            getStable.success(function(response){
                $scope.stableBranch = response[0];
            });
        };
        $scope.isCritical = function(branch) {
            var defects = branch.defects;
            if (defects && defects != 'undefined') {
                var filtered = defects.filter(function(obj) {
                    if (obj.exploit && obj.exploit != 'undefined') {
                        // console.log('obj ' , obj.exploit);
                        return obj;
                    } else {
                        return false;
                    }
                });
            return filtered.length > 0;
            } else {
                return false;
            }
        };


    }]);

    freeradius.controller('SocialFeeds', ['$scope', '$http', '$sce', '$filter', function($scope, $http, $sce, $filter) {
        $scope.getFeeds = function(count) {
            $scope.state = 'loading';
            $http({
                method: 'GET',
                // url: 'http://{{ site.url }}/api/components/',
                url: '/social.json',
                // params: {
                //     by_category: category
                // }
            }).then(function successCallback(response) {
                console.log('response ' , response);
                $scope.feeds = response.data;
                $scope.state = 'success';

            }, function errorCallback(response) {
                console.log('error response ' , response);
                $scope.state = 'error';
            });
        };
        $scope.trust = function(html) {
            return $sce.trustAsHtml(html);
        }
        $scope.toDate = function(string) {
            return $filter('date')(new Date(string), 'longDate');
        }
    }]);

    freeradius.directive('stableDownload', ['getStable', function(getStable){
        return {
            link: function(scope, elem, attrs) {
                scope.getStableBranch = function() {
                    getStable.success(function(response){
                        // console.log('response stableDownload' , response);
                        scope.stableBranch = response[0];
                    });
                };
                scope.getStableBranch()
            }
        }
    }]);


    // Grid with google image-like rows (FAQ and Careers pages)
    // --------------------------------------------------------

    freeradius.directive('mod',[ '$window', '$http', '$timeout', function(  $window, $http, $timeout ){

        var fixTheMargin = function(element, blockHeight){
            var box = element.find('.box');
            var block = element.find('.block');
            //Block is selected/displayed
            if(blockHeight > 0){
                var blockPadding = block.css('padding-top');
                blockPadding = parseInt(blockPadding, 10) * 2;
                block.css('margin-top', "-"+(blockHeight+blockPadding)+"px");
                box.css('margin-bottom', ''+(blockHeight+blockPadding+32)+"px");
            }
            //Block is hidden/not selected
            else{
                block.css('margin-top', "0");
                box.css('margin-bottom', '0');
            }
        }

        return{
            link: function($scope,element,attr){
                $scope.fixMargin = function() {
                    $timeout(function(){
                        var block = element.find('.block');
                        var blockHeight = angular.element(block).height();
                        fixTheMargin(element, blockHeight);
                    },100);
                }

                var win = angular.element($window);
                win.bind("resize",function(e){
                    var block = element.find('.block');
                    var blockHeight = angular.element(block).height();
                    fixTheMargin(element, blockHeight);
                });


                $scope.$on('triggerFixMargin', function(e) {
                    $scope.fixMargin();
                });

            }
        }
    }]);

})(jQuery, angular);
