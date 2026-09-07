const es = new EventSource('/stream');
const chatElem = document.getElementById("chat")
es.onmessage = (e) => { chatElem.append(e.data + "\n") };

const formElem = document.getElementById("new_message")
const msgElem = document.getElementById("msg")
formElem.onsubmit = async (e) => {
	e.preventDefault();
	await fetch('/', {method: 'POST', body: JSON.stringify({ msg: msgElem.value }) });
	msgElem.value = '';
	msgElem.focus();
}
