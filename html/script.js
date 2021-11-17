function playsound(table) {
    var file = table['file']
    var volume = table['volume']
    var audioPlayer = null;
    if (audioPlayer != null) {
        audioPlayer.pause();
    }
    if (volume == undefined) {
        volume = 0.2
    }
    audioPlayer = new Audio("./audio/" + file + ".ogg");
    audioPlayer.volume = volume;
    audioPlayer.play();
}

function countObject(ob) {
    var c = 0
    for (const i in ob) {
        c = c + 1
    }
    return c
}

function Progress(status) {
    var max = 0
    var value = 0
    for (const i in status) {
        if (typeof status[i] == 'object') {
            var parts = status[i]
            for (const val in parts) {
                if (parts[val] <= 0) {
                    value = value + 1
                }
                max = max + 1
            }
        } else {
            if (status[i] == 0) {
                value = value + 1
            }
            max = max + 1
        }
    }
    return (value / max * 100).toFixed(2)
}

window.addEventListener('message', function(event) {
    var data = event.data;
    if (event.data.type == 'project_status') {
        if (event.data.show) {
            document.getElementById('perf').style.display = 'block'
            var info = event.data.info
            if (info) {
                document.getElementById('name').innerHTML = '<img src="brands/'+info.brand+'.png" style="width:40px; position:absolute;right:55px;top:10px;">'+info.name
                document.getElementById('model').innerHTML = info.model
                document.getElementById('category').innerHTML = info.category
            }
        } else {
            document.getElementById('perf').style.display = 'none'
        }
        if (event.data.status) {
            const status = event.data.status
            document.getElementById('progress').innerHTML = Progress(status)
            for (const i in status) {
                //console.log(i)
                if (typeof status[i] == 'object') {
                    var parts = status[i]
                    var max = countObject(parts)
                    var value = 0
                    for (const val in parts) {
                        if (parts[val] <= 0) {
                            value = value + 1
                        }
                    }
                    //console.log(value/max*100,i)
                    document.getElementById(i).style.width = ''+(value / max) * 100+'%'
                } else {
                    //console.log(''+status[i] !== 1 && 100 || 0+'',i)
                    var val = 100
                    if (status[i] == 1) {
                        val = 0
                    }
                    document.getElementById(i).style.width = ''+val+'%'
                }
            }
        }
    }

});