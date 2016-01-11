require('./gradientui.css')

module.exports = function($) {

    require('./spectrum.js')($)

    window.dami = $

    var hexToRgb = function(hex) {
        var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
            r: parseInt(result[1], 16) / 255,
            g: parseInt(result[2], 16) / 255,
            b: parseInt(result[3], 16) / 255
        } : null;
    }
    
    var clamp = function(value, min, max) {
        return Math.max(min, Math.min(max, value));
    }
    
    var Dragger = function(parent, position, color) {
        // PROPERTIES
        this.parent = parent;
        this.position = position;
        this.color = color;
        this.dragging = false;
        this.moved = false;
        this.oldleft = undefined
        this.mousedownx = undefined;
        // DOM
        this.$this = $('<div class="gradient-dragger"></div>')
        this.$text = $('<span />')
        this.parent.$this.append( this.$this );
        this.$this.append( this.$text )
        this.$this.css("left", this.position * this.parent.width);
        this.$this.css("background-color", this.color);
        // EVENT
        this.$this.bind("click.dragger", {this : this}, function(event){event.data.this.click(event)});
        this.$this.bind("mousedown.dragger", {this : this}, function(event){event.data.this.mousedown(event)});
        $(window).bind("mouseup.dragger", {this : this}, function(event){event.data.this.mouseup(event)});
        $(window).bind("mousemove.dragger", {this : this}, function(event){event.data.this.mousemove(event)});
        // COLOR PICKER
        var dragger = this
        this.$this.spectrum({
            replacerClassName: 'customSpectrum',
            color: this.color,
            showButtons: false,
            showInput: true,
            preferredFormat: 'hex',
            beforeShow: function(){ return dragger.moved ? false : true },
            move: function(tc) { dragger.setColor(tc.toHexString()) }
        })

    }
    
    Dragger.prototype.click = function(event) {}
    
    Dragger.prototype.mousedown = function(event) {
        this.oldleft = parseInt(this.$this.css("left"), 10);
        this.mousedownx = event.pageX;
        this.dragging = true;
        this.moved = false;
        this.displayPosition(this.position);
    }
    
    Dragger.prototype.mouseup = function(event) {
        this.dragging = false;
        this.displayPosition(null);
    }
    
    Dragger.prototype.mousemove = function(event) {
        if(!this.dragging) { return; }
        
        var diff = event.pageX - this.mousedownx;
        var newleft = clamp(this.oldleft + diff, 0, this.parent.width );
        var newpos = newleft / this.parent.width
        
        this.setPosition( newpos );
        this.displayPosition( this.position );
        this.parent.redraw();

        this.moved = true;
    }

    Dragger.prototype.displayPosition = function(arg) {
        if (typeof arg === 'number') {
            this.$text.text(Math.round( arg * 100 ) / 100);
        } else if (arg) {
            this.$text.text(arg);
        } else {
            this.$text.text(null);
        }
    }
    
    Dragger.prototype.setPosition = function(pos) {
        this.position = pos;
        this.$this.css("left", pos * this.parent.width);
    }
    
    Dragger.prototype.setColor = function(color) {
        this.color = color;
        this.$this.css("background-color", color);
        this.$this.spectrum('set',color);
        this.parent.redraw();
    }
    
    var Gradient = function(parent, values) {
        // Canvas
        this.gradientview = $('<canvas class="gradient-view"></canvas>');
        this.canvas = this.gradientview.get(0);
        this.ctx = this.canvas.getContext('2d');
        // DOM
        this.$this = parent;
        this.$this.append(this.gradientview);
        // Properties
        this.width = 0;
        this.height = 0;
        this.draggerSize = 8;
        // draggers
        this.draggers = [];
        for ( var i = 0, len = values.length; i < len; i++ ) {
            this.draggers.push(new Dragger(this, values[i][0], values[i][1]));
        }
        // Init Size & Display
        this.resize();
        this.redraw();
    }

    Gradient.prototype.resize = function() {
        this.width = this.gradientview.width() - 6;
        this.height = this.gradientview.height();
        this.draggers.forEach(function(dragger){
            dragger.setPosition( dragger.position )
        })
    }
    
    Gradient.prototype.updateValues = function() {
        var aux = this.draggers.map(function(a){return [a.position, a.color];});
        aux.sort(function(a,b){return a[0]-b[0];});
        this.values = aux;
        if(this.callback !== undefined) {
            this.callback.fn(this.callback.data);
        }
    }
    
    Gradient.prototype.setValues = function(values) {
        this.values = values;
        for (var i = values.length - 1; i >= 0; i--) {
            var v = values[i];
            this.draggers[i].setPosition(v[0]);
            this.draggers[i].setColor(v[1]);
        };
    }
    
    Gradient.prototype.redraw = function() {
        this.updateValues();
        var values = this.values;
        
        var lingrad = this.ctx.createLinearGradient(0, 0, this.canvas.width, 0);
        for(var i=0; i<values.length; i++)
            lingrad.addColorStop(values[i][0], values[i][1]);
        
        this.ctx.fillStyle = lingrad;
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
    }
    
    Gradient.prototype.setUpdateCallback = function(callback, data) {
        this.callback = {};
        this.callback.fn = callback;
        this.callback.data = data;
    }
    
    var methods = {
        init : function(options) {
            
            var settings = $.extend( {
                  values         : [[0.2, "#FF0000"], [0.4, "#00FF00"], [0.6, "#0000FF"], [0.8, "#FFFFFF"]]
                }, options);
            
            return this.each(function(){
                var aux = new Gradient($(this), settings.values);
                $(window).on('resize',function(){
                    aux.resize()
                    aux.redraw()
                })
                $(this).data("gradient", aux);
            });
        },
        
        destroy : function() {
            return this.each(function(){
                $(window).unbind(".gradient");
            });
        },
        
        getValuesRGBS : function() {
            
            var values = $(this).data("gradient").values;
            var valuesRGBS = values.map(function(a){
                var rgb = hexToRgb(a[1]);
                return [rgb.r, rgb.g, rgb.b, a[0]]
            });
            return valuesRGBS;
        },
        
        setValues : function(values) {
            $(this).data("gradient").setValues(values);
        },
        
        getValues : function() {
            return $(this).data("gradient").values;
        },
        
        setUpdateCallback : function(callback, data) {
            $(this).data("gradient").setUpdateCallback(callback, data);
            return this;
        }
    };
    
    $.fn.gradient = function(method) {
        if(methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if(typeof method === 'object' || !method) {
            return methods.init.apply(this, arguments);
        } else {
            $.error('Method ' +  method + ' does not exist on gradientui');
        }
    };

}